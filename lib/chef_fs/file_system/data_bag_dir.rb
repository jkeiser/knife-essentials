require 'chef_fs/file_system/rest_list_dir'
require 'chef_fs/file_system/data_bag_item'
require 'chef_fs/file_system/not_found_error'
require 'chef_fs/file_system/must_delete_recursively_error'

module ChefFS
  module FileSystem
    class DataBagDir < RestListDir
      def initialize(name, parent, exists = nil)
        super(name, parent)
        @exists = nil
      end

      def dir?
        exists?
      end

      def read
        # This will only be called if dir? is false, which means exists? is false.
        raise ChefFS::FileSystem::NotFoundError, "#{path_for_printing} not found"
      end

      def exists?
        if @exists.nil?
          @exists = parent.children.any? { |child| child.name == name }
        end
        @exists
      end

      def _make_child_entry(name, exists = nil)
        DataBagItem.new(name, self, exists)
      end

      def delete(recurse)
        if !recurse
          raise ChefFS::FileSystem::MustDeleteRecursivelyError.new, "#{path_for_printing} must be deleted recursively"
        end
        begin
          rest.delete_rest(api_path)
        rescue Net::HTTPServerException
          if $!.response.code == "404"
            raise ChefFS::FileSystem::NotFoundError.new($!), "#{path_for_printing} not found"
          end
        end
      end
    end
  end
end
