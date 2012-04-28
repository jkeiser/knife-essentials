require 'chef_fs/file_system/base_fs_object'
require 'chef_fs/file_system/not_found_error'

module ChefFS
  module FileSystem
    class NonexistentFSObject < BaseFSObject
      def initialize(name, parent)
        super
      end

      def exists?
        false
      end

      def read
        raise ChefFS::FileSystem::NotFoundError, "Nonexistent #{path_for_printing}"
      end
    end
  end
end
