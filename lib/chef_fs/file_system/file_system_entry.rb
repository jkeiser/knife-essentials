require 'chef_fs/file_system/base_fs_dir'
require 'chef_fs/file_system/rest_list_dir'
require 'chef_fs/path_utils'

module ChefFS
  module FileSystem
    class FileSystemEntry < BaseFSDir
      def initialize(name, parent, file_path = nil)
        super(name, parent)
        @file_path = file_path || "#{parent.file_path}/#{name}"
      end

      attr_reader :file_path

      def path_for_printing
        ChefFS::PathUtils::relative_to(file_path, File.absolute_path(Dir.pwd))
      end

      def children
        @children ||= Dir.entries(file_path).select { |entry| entry != '.' && entry != '..' }.map { |entry| FileSystemEntry.new(entry, self) }
      end

      def dir?
        File.directory?(file_path)
      end

      def read
        begin
          IO.read(file_path)
        rescue IONotFoundException # TODO real exception
          raise NotFoundException, $!
        end
      end
    end
  end
end
