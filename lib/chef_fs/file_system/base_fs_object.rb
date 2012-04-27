require 'chef_fs/path_utils'

module ChefFS
  module FileSystem
    class BaseFSObject
      def initialize(name, parent)
        @parent = parent
        @name = name
        if parent
          @path = ChefFS::PathUtils::join(parent.path, name)
        else
          if name != ''
            raise ArgumentError, "Name of root object must be empty string: was '#{name}' instead"
          end
          @path = '/'
        end
      end

      attr_reader :name
      attr_reader :parent
      attr_reader :path

      def root
        parent ? parent.root : self
      end

      def path_for_printing
        if parent
          ChefFS::PathUtils::join(parent.path_for_printing, name)
        else
          name
        end
      end

      def dir?
        false
      end

      def exists?
        true
      end

      def content_type
        :text
      end

      def child(name)
        NonexistentFSObject.new(name, self)
      end

      # Override can_have_child? to report whether a given file *could* be added
      # to this directory.  (Some directories can't have subdirs, some can only have .json
      # files, etc.)
      def can_have_child?(name, is_dir)
        false
      end

      # Important directory attributes: name, parent, path, root
      # Overridable attributes: dir?, child(name), path_for_printing
      # Abstract: read, write, delete, children
    end
  end
end
