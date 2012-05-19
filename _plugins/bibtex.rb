#
# Adds bibtex bibliographies.
# The 'bibliography' liquid block loads a bibliography from the argument if
# given and otherwise from the configuration option "bibtex: file: ". Inside
# the block, the 'bibliography' variable is a list of reference objects. Each
# reference object has a .html attribute giving the formatted html for the
# reference, and other attributes corresponding to the citeproc values.
#
# Options in the 'bibtex' configuration section:
#   citation_style: citation style for citeproc
#   citation_locale: citation locale for citeproc
#   skip_keys: space separated bibtex keys to remove before showing a reference
#   sort_keys: space separated bibtex keys to sort on (see below)
#
# Sorting: The keys in sort_keys are given in order of precedence. If a key is
# prefixed with -, then the sort is reversed on that key. Some special keys are
# available for sorting:
#   date: the date including any components that are available
#   authors: the author string formatted according to the set style
#

require 'bibtex'
require 'citeproc'

module Jekyll
  class Reference
    def initialize(citeproc, html)
      @data = citeproc.dup
      @data['html'] = html
    end

    def to_liquid
      @data
    end
  end

  class BibliographyBlock < Liquid::Block
    def initialize(tag_name, param_text, tokens)
      super
      @filename = param_text.length > 0 ? param_text.strip : nil
    end

    def sort_bib(citeproc_bib, sort_keys)
      citeproc_bib.sort! do |citeproc1, citeproc2|
        order = sort_keys.each do |key|
          if key[0] == '-' then
            dir = -1
            key = key[1..-1]
          else
            dir = 1
          end
          value1, value2 = [citeproc1, citeproc2].map do |citeproc|
              value = citeproc[key]
              begin
                Float(value)
              rescue
                value
              end
            end
          cmp = (value1 <=> value2)
          if cmp == nil or cmp == 0 then
            next
          else
            break cmp * dir
          end
        end
        order == sort_keys ? 0 : order
      end
    end

    def add_extra_sort_keys(citeproc_bib, cite_style, cite_locale)
      citeproc_bib.each do |citeproc|
        citeproc['authors'] = CiteProc.process({ 'author' => citeproc['author'] }, :style => cite_style, :locale => cite_locale) if citeproc.include?('author')
        citeproc['date'] = citeproc['issued']['date-parts'].flatten if citeproc.include?('issued') and citeproc['issued'].include?('date-parts')
      end
    end

    def remove_skip_keys(citeproc_bib, skip_keys)
      citeproc_bib.each do |citeproc|
        skip_keys.each do |key|
          citeproc.delete(key)
          citeproc.delete(key.upcase)
          citeproc.delete(key.downcase)
        end
      end
    end

    def render(context)
      site = context['site']
      config = site['bibtex']
      cite_style = config['citation_style'] || 'apa'
      cite_locale = config['citation_locale'] || 'en'
      skip_keys = (config['skip_keys'] || "").split()
      sort_keys = (config['sort_keys'] || "-date authors title").split()

      filename = File.join(site['source'], @filename || config['file'])
      bibtex = File.open(filename) { |file| BibTeX.parse(file) }
      citeproc_bib = bibtex.map { |item| item.to_citeproc }
      add_extra_sort_keys(citeproc_bib, cite_style, cite_locale)
      sort_bib(citeproc_bib, sort_keys)
      remove_skip_keys(citeproc_bib, skip_keys)
      context['bibliography'] = citeproc_bib.map do |citeproc|
          html = CiteProc.process(citeproc, :style => cite_style, :locale => cite_locale, :format => 'html')
          Reference.new(citeproc, html)
        end
      super
    end
  end
end

Liquid::Template.register_tag('bibliography', Jekyll::BibliographyBlock)
