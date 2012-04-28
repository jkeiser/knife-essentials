require 'chef_fs/file_system/file_system_entry'
require 'chef/cookbook/chefignore'

module ChefFS
  module FileSystem
    # ChefRepositoryFileSystemEntry works just like FileSystemEntry,
    # except it pretends files in /cookbooks/chefignore don't exist
    class ChefRepositoryFileSystemEntry < FileSystemEntry
      def initialize(name, parent, file_path = nil)
        super(name, parent, file_path)
        # Load /cookbooks/chefignore
        if name == "cookbooks" && path == "/cookbooks" # We check name first because it's a faster fail than path
          @chefignore = Chef::Cookbook::Chefignore.new(self.file_path)
        end
      end

      def children
        @children ||= Dir.entries(file_path).select { |entry| entry != '.' && entry != '..' && !ignored?(entry) }
                                            .map { |entry| ChefRepositoryFileSystemEntry.new(entry, self) }
      end

      attr_reader :chefignore

      private

      def ignored?(child_name)
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
