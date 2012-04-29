require 'chef_fs/file_system/base_fs_dir'
require 'chef_fs/file_system/rest_list_dir'
require 'chef_fs/file_system/not_found_error'
require 'chef_fs/path_utils'
require 'fileutils'

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
        begin
          @children ||= Dir.entries(file_path).select { |entry| entry != '.' && entry != '..' }.map { |entry| FileSystemEntry.new(entry, self) }
        rescue Errno::ENOENT
          raise ChefFS::FileSystem::NotFoundError.new($!), "#{file_path} not found"
        end
      end

      def create_child(child_name, file_contents=nil)
        result = FileSystemEntry.new(child_name, self)
        if file_contents
          result.write(file_contents)
        else
          Dir.mkdir(result.file_path)
        end
        result
      end

      def dir?
        File.directory?(file_path)
      end

      def delete
        if dir?
          FileUtils.rm_rf(file_path)
        else
          File.delete(file_path)
        end
      end

      def read
        begin
          IO.read(file_path)
        rescue Errno::ENOENT
          raise ChefFS::FileSystem::NotFoundError.new($!), "#{file_path} not found"
        end
      end

      def write(content)
        File.open(file_path, 'w') do |file|
          file.write(content)
        end
      end
    end
  end
end
