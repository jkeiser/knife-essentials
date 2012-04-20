require 'chef_fs/file_system/base_fs_object'

module ChefFS
  module FileSystem
    class NonexistentFSObject < BaseFSObject
      def initialize(name, parent)
        super
      end

      def exists?
        false
      end

      def child(name)
        NonexistentFSObject.new(name, self)
      end

      def read
        raise ChefFS::FileSystem::NotFoundException, "Nonexistent object"
      end
    end
  end
end
