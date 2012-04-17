require 'chef_fs/file_system/file_system_entry'

module ChefFS
  module FileSystem
    class FileSystemRootDir < FileSystemEntry
      def initialize(file_path)
        super("", nil, file_path)
      end
    end
  end
end
