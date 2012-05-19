#
# This is a monkey-patched hack to support a list of featured posts.
# A list of post file basenames (with or without the extensions) is read from
# a file specifed by the 'featured: list_file:' option. Posts may be given
# 'featured_text' and 'featured_image' variables in front matter. For each
# post that is in the list_file and has at least one of featured_text or
# featured_image, post.now_featured will be set to true. post.now_featured
# will be false for all other posts.
#

module Jekyll
  class Site
    alias _featured_old_read_posts read_posts

    attr_reader :featured_list

    def read_posts(*args)
      _featured_old_read_posts(*args)
      filename = File.join(@config['source'], @config['featured']['list_file'])
      instance_variable_set(:@featured_list,
          begin
            File.open(filename) do |file|
              file.readlines.map { |l| l.chomp }
            end
          rescue
            []
          end
        )
    end
  end

  class Post
    alias _featured_old_to_liquid to_liquid

    def to_liquid(*args)
      data = _featured_old_to_liquid(*args)
      valid = (@data['featured_text'] != nil or @data['featured_image'] != nil)
      in_list = (@site.featured_list.include?(@name) or @site.featured_list.include?(File.basename(@name, '.*')))
      data.merge({ 'now_featured' => (valid and in_list), 'featured_image' => (data['featured_image'] or @site.config['featured']['default_image']) })
    end
  end
end
