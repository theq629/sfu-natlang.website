#
# Support for a list of featured posts.
# A list of post file basenames (with or without the extensions) is read from
# a file specifed by a paramter, or if not given then the 'featured: list_file:'
# configuration option. Posts may be given 'featured_text' and 'featured_image'
# variables in front matter. Inside the 'featured' liquid block, the variable
# 'featured' will contain those posts that are in the list and have both
# variables set.
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

      # Get the list of current featured posts as basenames of post files.
      filename = File.join(site['source'], @filename || site['featured']['list_file'])
      featured_list =
          begin
            File.open(filename) do |file|
              file.readlines.map { |l| l.chomp }
            end
          rescue
            []
          end

      # Make a list of featured posts with the required front matter fields, and
      # put it in a liquid variable.
      context['featured'] = posts.select do |post|
          name = post.instance_variable_get(:@name)
          in_list = (featured_list.include?(name) or featured_list.include?(File.basename(name, '.*')))
          has_data = (post.data['featured_text'] != nil and post.data['featured_image'] != nil)
          $stderr.puts "error: #{name} is in a featured list but does not have the needed front matter variables" if in_list and not has_data
          in_list and has_data
        end
      super
    end
  end
end

Liquid::Template.register_tag('featured', Jekyll::FeaturedBlock)
