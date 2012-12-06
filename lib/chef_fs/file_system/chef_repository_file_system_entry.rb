require 'chef_fs/file_system/file_system_entry'
require 'chef/cookbook/chefignore'
require 'chef/cookbook/cookbook_version_loader'
require 'chef/node'
require 'chef/role'
require 'chef/environment'
require 'chef/data_bag_item'
require 'chef/client'

module ChefFS
  module FileSystem
    # ChefRepositoryFileSystemEntry works just like FileSystemEntry,
    # except it pretends files in /cookbooks/chefignore don't exist
    # and it can inflate Chef objects
    class ChefRepositoryFileSystemEntry < FileSystemEntry
      def initialize(name, parent, file_path = nil)
        super(name, parent, file_path)
        # Load /cookbooks/chefignore
        if name == "cookbooks" && path == "/cookbooks" # We check name first because it's a faster fail than path
          @chefignore = Chef::Cookbook::Chefignore.new(self.file_path)
        # If we are a cookbook or a cookbook subdirectory, empty directories
        # underneath us are ignored (since they cannot be uploaded)
        elsif parent && parent.name === "cookbooks" && parent.path == "/cookbooks"
          @ignore_empty_directories = true
        elsif parent && parent.ignore_empty_directories?
          @ignore_empty_directories = true
        end
      end

      attr_reader :chefignore

      def ignore_empty_directories?
        @ignore_empty_directories
      end

      def chef_object
        begin
          if parent.path == "/cookbooks"
            loader = Chef::Cookbook::CookbookVersionLoader.new(file_path, parent.chefignore)
            loader.load_cookbooks
            return loader.cookbook_version
          end

          # Otherwise the information to inflate the object, is in the file (json_class).
          return Chef::JSONCompat.from_json(read)
        rescue
          Chef::Log.error("Could not read #{path_for_printing} into a Chef object: #{$!}")
        end
        nil
      end

      def children
        @children ||= begin
          file_paths = Array(File.basename(file_path) == 'cookbooks' ? Chef::Config.cookbook_path : file_path)
          childs = []
          file_paths.each do |file_path|
            childs += Dir.entries(file_path).
              select { |entry| entry != '.' && entry != '..' && !ignored?(entry) }.
              map { |entry| ChefRepositoryFileSystemEntry.new(entry, self, "#{file_path}/#{entry}") }
          end
          childs
        end
      end

      attr_reader :chefignore

      private

      def ignored?(child_name)
        # empty directories inside a cookbook are ignored
        if ignore_empty_directories?
          child_path = PathUtils.join(file_path, child_name)
          if File.directory?(child_path) && Dir.entries(child_path) == [ '.', '..' ]
            return true
          end
        end

        ignorer = self
        begin
          if ignorer.chefignore
            # Grab the path from entry to child
            path_to_child = child_name
            child = self
            while child != ignorer
              path_to_child = PathUtils.join(child.name, path_to_child)
              child = child.parent
            end
            # Check whether that relative path is ignored
            return ignorer.chefignore.ignored?(path_to_child)
          end
          ignorer = ignorer.parent
        end while ignorer
      end

    end
  end
end
