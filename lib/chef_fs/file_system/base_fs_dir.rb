require 'chef_fs/file_system/base_fs_object'
require 'chef_fs/file_system/nonexistent_fs_object'

module ChefFS
  module FileSystem
    class BaseFSDir < BaseFSObject
      def initialize(name, parent)
        super
      end

      def dir?
        true
      end

      # Override child(name) to provide a child object by name without the network read
      def child(name)
        children.select { |child| child.name == name }.first || NonexistentFSObject.new(name, self)
      end

      def can_have_child?(name, is_dir)
        true
      end

      # Abstract: children
    end
  end
end
