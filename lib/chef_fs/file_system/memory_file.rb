require 'chef_fs/file_system/base_fs_object'

module ChefFS
  module FileSystem
    class MemoryFile < ChefFS::FileSystem::BaseFSObject
      def initialize(name, parent, value)
        super(name, parent)
        @value = value
      end
      def read
        return @value
      end
    end
  end
end
