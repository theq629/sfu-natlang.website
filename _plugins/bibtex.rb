#
# Adds bibtex bibliographies.
#
# Bibliography Liquid block: 'bibliography' block loads a bibliography from
# the argument if given and otherwise from the configuration option 'file'.
# Inside the block, the 'bibliography' variable is a list of reference objects.
# ach # reference object has a .html attribute giving the formatted html for the
# reference, and other attributes corresponding to the citeproc values.
#
# Individual bibliography entry pages: individual pages are generated for each
# entry in the default bibliography. They are placed in a directory given by the
# option 'page_dir', with a style given by 'page_style'. The entry is made
# available in Liquid as 'page.publication'.
#
# Sorting: The keys in 'sort_keys' determine the order of a bibliography. They
# are given in order of precedence. If a key is prefixed with -, then the sort
# is reversed on that key. The special added properties may be useful for sorting.
#
# Properties added to bibtex:
#   order: the entry index in the input file
#   monthnum: the month as a number
#   authors: the author string formatted according to the set style
#   pageurl: the URL of the individial entry page, if there is one
#
# Options in the 'bibtex' configuration section:
#   citation_style: citation style for citeproc
#   citation_locale: citation locale for citeproc
#   skip_keys: space separated bibtex keys to remove before showing a reference
#   sort_keys: space separated bibtex keys to sort on (see below)
#   page_dir: the directory to contain individual entry pages
#   page_style: the style for individual entry pages
#

require 'bibtex'
require 'citeproc'

module Jekyll
  module Bibtex
    # Sort a list of bib entries in bibtex format with given keys.
    def self.sort_bib(bibtex_bib, sort_keys)
      bibtex_bib.sort! do |bibtex1, bibtex2|
        order = sort_keys.each do |key|
          # Handle the sort order reversal prefix.
          if key[0] == '-' then
            dir = -1
            key = key[1..-1]
          else
            dir = 1
          end
          # Take the values corresponding to the key from each entry. If
          # they look like numbers then make them floats.
          value1, value2 = [bibtex1, bibtex2].map do |bibtex|
              value = bibtex[key]
              begin
                Float(value)
              rescue
                value
              end
            end
          # Compare values, stopping for this bib entry if the key lets us
          # establish order.
          cmp = (value1 <=> value2)
          if cmp == nil or cmp == 0 then
            next
          else
            break cmp * dir
          end
        end
        # If the loop over keys got to the end, the two entries are tied; if it
        # broke early then we have an order for the entries.
        order == sort_keys ? 0 : order
      end
    end

    # Make the basename of a URL for an individual reference page.
    def self.page_baseurl(bibtex)
      CGI.escape(bibtex['fileorder'])
    end

    @month_lookup = { 'jan' => 1, 'feb' => 2, 'mar' => 3, 'apr' => 4, 'may' => 5, 'jun' => 6, 'jul' => 7, 'aug' => 8, 'sep' => 9, 'oct' => 10, 'nov' => 11, 'dec' => 12 }

    def self.month_to_integer(month)
      @month_lookup[month.downcase] || month
    end

    # Remove keys to be skipped in the formatted html reference.
    def self.remove_skip_keys(bibtex, skip_keys)
      skip_keys.each do |key|
        # We can't be sure of capitalization, so try the major possibilities.
        bibtex.delete(key)
        bibtex.delete(key.upcase)
        bibtex.delete(key.downcase)
      end
    end

    # Add formatted output to an entry.
    def self.format_entry(bibtex, out_skip_keys, bibtex_skip_keys, cite_style, cite_locale)
      html_bibtex = bibtex.dup
      bibtex_bibtex = bibtex.dup
      # HTML formatted reference.
      remove_skip_keys(html_bibtex, out_skip_keys)
      bibtex['html'] = CiteProc.process(html_bibtex.to_citeproc, :style => cite_style, :locale => cite_locale, :format => 'html')
      # Filtered bibtex as string.
      remove_skip_keys(bibtex_bibtex, bibtex_skip_keys)
      bibtex['bibtex'] = bibtex_bibtex.to_s
    end

    # Augment an entry with properties useful for sorting and output.
    def self.augment_entry(i, bibtex, on_default, page_dir, cite_style, cite_locale)
      bibtex['fileorder'] = i.to_s
      # Add a URL for the individual reference page if we are using the
      # default bibliography file (but not otherwise, since we only
      # generate individual pages from the default bibliography).
      if on_default and page_dir != nil then
        bibtex['pageurl'] = File.join(page_dir, page_baseurl(bibtex))
      end
      # Strip curly braces off the abstract.
      bibtex['abstract'] = bibtex['abstract'].gsub(/^{+/, '').gsub(/}+$/, '') if bibtex['abstract'] != nil
      # It's hard to sort directly on the author information, so we add a
      # text verson by formatting a cut-down copy of the entry.
      citeproc = bibtex.to_citeproc
      bibtex['authors'] = CiteProc.process({ 'author' => citeproc['author'] }, :style => cite_style, :locale => cite_locale) if citeproc['author'] != nil
      # Numeric month.
      bibtex['monthnum'] = month_to_integer(bibtex['month'].downcase) if bibtex['month'] != nil
    end

    # Cache for loaded bibliographies to avoid repeating parsing and sorting.
    @bib_cache = {}

    # Make a list of references for a bibliography.
    def self.make_references(site, source, config, opts={})
        cite_style = config['citation_style'] || 'apa'
        cite_locale = config['citation_locale'] || 'en'
        out_skip_keys = (config['out_skip_keys'] || "").split()
        bibtex_skip_keys = (config['bibtex_skip_keys'] || "").split()
        sort_keys = (config['sort_keys'] || "-year -monthnum title order").split()
        page_dir = config['page_dir']

        filename = opts[:filename]
        on_default = false
        if filename == nil then
          filename = config['file']
          on_default = true
        end
        filename = File.join(source, filename)

        if @bib_cache.key?(filename) then
          @bib_cache[filename]
        else
          bib = File.open(filename) { |f| BibTeX.parse(f) }
          bib = bib.map { |bt| bt } # get a plain list
          bib.each_with_index do |bibtex, i|
            format_entry(bibtex, out_skip_keys, bibtex_skip_keys, cite_style, cite_locale)
            augment_entry(i, bibtex, on_default, page_dir, cite_style, cite_locale)
          end
          sort_bib(bib, sort_keys)
          @bib_cache[filename] = bib
          bib
        end
    end
  end

  # This is the type for the objects which will be passed to the liquid
  # interface. It's just the bibtex that we store, including the extra sort
  # keys and the formatted output keys.
  class Reference
    def initialize(bibtex)
      @data = {}
      # We need to get a hash with string keys.
      bibtex.each_pair { |k, v| @data[k.to_s] = v }
    end

    def to_liquid
      @data
    end
  end

  # Liquid block for bibliographies.
  class BibliographyBlock < Liquid::Block
    def initialize(tag_name, param_text, tokens)
      super
      # Use a given bibfile if there is a paramter, otherwise the default.
      @filename = param_text.length > 0 ? param_text.strip : nil
    end

    # Output html.
    def render(context)
      # Make a list of reference objects available as a liquid variable.
      site = context['site']
      context['bibliography'] = Jekyll::Bibtex.make_references(site, site['source'], site['bibtex'], :filename => @filename).map { |bt| Reference.new(bt) }
      super
    end
  end

  # Jekyll individual publication page.
  class PublicationPage < Page
    def initialize(site, dir, layout, bibtex)
      @site = site
      @base = site.source
      @dir = File.join(dir, Jekyll::Bibtex.page_baseurl(bibtex))
      @name = 'index.html'

      process(name)
      read_yaml(File.join(@base, '_layouts'), layout + '.html')
      data['title'] = bibtex['title'] != nil ? "#{bibtex['title']}" : 'Publication'
      data['title'] += " (#{bibtex['year']})" if bibtex['year'] != nil
      data['layout'] = layout
      data['publication'] = Reference.new(bibtex)
    end
  end

  # Jekyll generator for individual publication pages from the default
  # bibliography.
  class PublicationPageGenerator < Generator
    safe true

    def generate(site)
      dir = site.config['bibtex']['page_dir']
      layout = site.config['bibtex']['page_layout']
      if dir != nil and layout != nil then
        Jekyll::Bibtex.make_references(site, site.source, site.config['bibtex']).each do |bibtex|
          page = PublicationPage.new(site, dir, layout, bibtex)
          page.render(site.layouts, site.site_payload)
          page.write(site.dest)
          site.pages << page
        end
      end
    end
  end
end

Liquid::Template.register_tag('bibliography', Jekyll::BibliographyBlock)
