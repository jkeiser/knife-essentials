require 'chef_fs/file_system/rest_list_dir'
require 'chef_fs/file_system/data_bag_dir'

module ChefFS
  module FileSystem
    class DataBagsDir < RestListDir
      def initialize(parent)
        super("data_bags", parent, "data")
      end

      def child(name)
        result = @children.select { |child| child.name == name }.first if @children
        result || DataBagDir.new(name, self)
      end

      def children
        begin
          @children ||= rest.get_rest(api_path).keys.map do |entry|
            DataBagDir.new(entry, self, true)
          end
        rescue Net::HTTPServerException
          if $!.response.code == "404"
            raise ChefFS::FileSystem::NotFoundError.new($!), "#{path_for_printing} not found"
          else
            raise
          end
        end
      end

      def can_have_child?(name, is_dir)
        is_dir
      end

      def create_child(name, file_contents)
        begin
          rest.post_rest(api_path, { 'name' => name })
        rescue Net::HTTPServerException
          if $!.response.code != "409"
            raise
          end
        end
        DataBagDir.new(name, self, true)
      end
    end
  end
end
