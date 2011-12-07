require 'chef_fs/file_system/rest_list_dir'
require 'chef_fs/file_system/cookbook_dir'

class ChefFS
  module FileSystem
    class CookbooksDir < RestListDir
      def initialize(parent)
        super("cookbooks", parent)
      end

      def child(name)
        result = @children.select { |child| child.name == name }.first if @children
        result || CookbookDir.new(name, self)
      end

      def children
        @children ||= rest.get_rest(api_path).map { |key, value| CookbookDir.new(key, self, value) }
      end
    end
  end
end
