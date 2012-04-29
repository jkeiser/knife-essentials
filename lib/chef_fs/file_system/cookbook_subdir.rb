require 'chef_fs/file_system/base_fs_dir'

module ChefFS
  module FileSystem
    class CookbookSubdir < BaseFSDir
      def initialize(name, parent, ruby_only, recursive)
        super(name, parent)
        @children = []
        @ruby_only = ruby_only
        @recursive = recursive
      end

      attr_reader :versions
      attr_reader :children

      def add_child(child)
        @children << child
      end

      def can_have_child?(name, is_dir)
        if is_dir
          return false if !@recursive
        else
          return false if @ruby_only && name !~ /\.rb$/
        end
        true
      end

      def rest
        parent.rest
      end
    end
  end
end
