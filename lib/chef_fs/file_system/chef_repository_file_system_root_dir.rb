require 'chef_fs/file_system/chef_repository_file_system_entry'

module ChefFS
  module FileSystem
    class ChefRepositoryFileSystemRootDir < ChefRepositoryFileSystemEntry
      def initialize(file_path)
        super("", nil, file_path)
      end
    end
  end
end
