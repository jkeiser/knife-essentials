require 'chef_fs/file_system/base_fs_dir'
require 'chef_fs/file_system/rest_list_entry'
require 'chef_fs/file_system/not_found_error'

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
    end
  end
end
