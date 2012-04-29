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
        @children ||= rest.get_rest(api_path).keys.map { |entry| DataBagDir.new(entry, self, true) }
      end

      def can_have_child?(name, is_dir)
        is_dir
      end
    end
  end
end
