require 'chef_fs/file_system/base_fs_dir'

# TODO: take environment into account

module ChefFS
  module FileSystem
    class CookbookSubdir < BaseFSDir
      def initialize(name, parent)
        super(name, parent)
        @children = []
      end

      attr_reader :versions
      attr_reader :children

      def add_child(child)
        @children << child
      end

      def rest
        parent.rest
      end
    end
  end
end
