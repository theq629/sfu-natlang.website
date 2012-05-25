#
# Support for a list of featured posts.
# Featured items are read from a file specifed by a paramter, or if not given
# then the 'featured: list_file:' configuration option. The file is a YAML
# list where each item can have "url" (the URL to link to) , "img" (the URL
# for an image) and "text" properties.
#

module Jekyll
  class FeaturedBlock < Liquid::Block
    def initialize(tag_name, param_text, tokens)
      super
      @filename = param_text.length > 0 ? param_text.strip : nil
    end

    def render(context)
      site = context['site']
      posts = site['posts']

      filename = File.join(site['source'], @filename || site['featured']['list_file'])
      context['featured'] =
          begin
            File.open(filename) do |file|
              YAML::load(file)
            end
          rescue
            []
          end
      super
    end
  end
end

Liquid::Template.register_tag('featured', Jekyll::FeaturedBlock)
