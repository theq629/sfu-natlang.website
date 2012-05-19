#
# This lets default front matter variables be set by page type.
# Eg the following sets the default layout "post" for all posts.
#   default_front_matter:
#     ./_posts:
#       layout: post
#

module Jekyll
  module Convertible
    alias _defaultpostlayout_old_read_yaml read_yaml

    def read_yaml(base, name)
      _defaultpostlayout_old_read_yaml(base, name)

      source = File.join(@site.config['source'])
      rel_base =
        '.' +
        if base.start_with?(source) then base[source.length..-1]
        else base
        end
      defaults =
        begin
          @site.config['default_front_matter'][rel_base] || {}
        rescue
          {}
        end

      defaults.each_pair do |key, value|
        @data[key] ||= value
      end
    end
  end
end
