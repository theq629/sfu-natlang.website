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
#   date: the date including any components that are available
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
    # Sort a list of bib entries in citeproc format with given keys.
    def self.sort_bib(bib, sort_keys)
      bib.sort! do |(_, citeproc1), (_, citeproc2)|
        order = sort_keys.each do |key|
          # Handle the sort order reversal prefix.
          if key[0] == '-' then
            dir = -1
            key = key[1..-1]
          else
            dir = 1
          end
          # Take the values corresponding to the key from each citeproc. If
          # they look like numbers then make them floats.
          value1, value2 = [citeproc1, citeproc2].map do |citeproc|
              value = citeproc[key]
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
    def self.page_baseurl(citeproc)
      CGI.escape(citeproc['fileorder'])
    end

    # Augment a citeproc bib entry with extra keys useful for sorting.
    def self.add_extra_sort_keys(citeproc, cite_style, cite_locale)
      # It's hard to sort directly on the author information, so we add a
      # text verson by formatting a cut-down copy of the entry.
      citeproc['authors'] = CiteProc.process({ 'author' => citeproc['author'] }, :style => cite_style, :locale => cite_locale) if citeproc.include?('author')
      # This is the date as one property.
      citeproc['date'] = citeproc['issued']['date-parts'].flatten if citeproc.include?('issued') and citeproc['issued'].include?('date-parts')
    end

    # Remove keys to be skipped in the formatted html reference.
    def self.remove_skip_keys(citeproc, skip_keys)
      skip_keys.each do |key|
        # Citeproc changes some capitalization, so try everything.
        citeproc.delete(key)
        citeproc.delete(key.upcase)
        citeproc.delete(key.downcase)
      end
    end

    # Cache for loaded bibliographies to avoid repeating parsing and sorting.
    @bib_cache = {}

    # Make a list of references for a bibliography.
    def self.make_references(site, source, config, opts={})
        # Get configuration options.
        cite_style = config['citation_style'] || 'apa'
        cite_locale = config['citation_locale'] || 'en'
        skip_keys = (config['skip_keys'] || "").split()
        sort_keys = (config['sort_keys'] || "-date authors title").split()

        # Load, parse, and massage the bibligraphy.
        filename = File.join(source, opts[:filename] || config['file'])
        if @bib_cache.include?(filename) then
          bib = @bib_cache[filename]
        else
          bibtex_bib = File.open(filename) { |file| BibTeX.parse(file) }
          bib = bibtex_bib.map { |bt| [bt, bt.to_citeproc] }
          bib.each_with_index do |(_, citeproc), i|
            citeproc['fileorder'] = i.to_s
            add_extra_sort_keys(citeproc, cite_style, cite_locale)
            # Add a URL for the individual reference page if we are using the
            # default bibliography file (but not otherwise, since we only
            # generate individual pages from the default bibliography).
            if config.include?('page_dir') and filename == File.join(source, config['file']) then
              dir = config['page_dir']
              citeproc['pageurl'] = File.join(dir, page_baseurl(citeproc))
            end
            # Strip curly braces off the abstract, since citeproc doesn't seem
            # to do that.
            citeproc['abstract'] = citeproc['abstract'].gsub(/^{+/, '').gsub(/}*$/, '') if citeproc.include?('abstract')
          end
          sort_bib(bib, sort_keys)
          @bib_cache[filename]
        end

        # Now we format each bib entry separately.
        bib.map do |bibtex, citeproc|
            use_citeproc = citeproc.dup
            remove_skip_keys(use_citeproc, skip_keys)
            #$stderr.puts citeproc
            [bibtex, citeproc, CiteProc.process(use_citeproc, :style => cite_style, :locale => cite_locale, :format => 'html')]
          end
    end
  end

  # This is the type for the objects which will be passed to the liquid
  # interface. It's just the data from citeproc (with any custom properties
  # added) plus the formatted html for the reference.
  class Reference
    def initialize(citeproc, bibtex, html)
      @data = citeproc.dup
      @data['html'] = html
      @data['bibtex'] = bibtex.to_s
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
      context['bibliography'] = Jekyll::Bibtex.make_references(site, site['source'], site['bibtex'], :filename => @filename).map { |bt, cp, h| Reference.new(cp, bt, h) }
      super
    end
  end

  # Jekyll individual publication page.
  class PublicationPage < Page
    def initialize(site, dir, layout, bibtex, citeproc, html)
      @site = site
      @base = site.source
      @dir = File.join(dir, Jekyll::Bibtex.page_baseurl(citeproc))
      @name = 'index.html'

      process(name)
      read_yaml(File.join(@base, '_layouts'), layout + '.html')
      data['title'] = "#{citeproc['title']} (#{citeproc['issued']['date-parts'][0][0]})"
      data['layout'] = layout
      data['publication'] = Reference.new(citeproc, bibtex, html)
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
        Jekyll::Bibtex.make_references(site, site.source, site.config['bibtex']).each do |bibtex, citeproc, html|
          page = PublicationPage.new(site, dir, layout, bibtex, citeproc, html)
          page.render(site.layouts, site.site_payload)
          page.write(site.dest)
          site.pages << page
        end
      end
    end
  end
end

Liquid::Template.register_tag('bibliography', Jekyll::BibliographyBlock)
