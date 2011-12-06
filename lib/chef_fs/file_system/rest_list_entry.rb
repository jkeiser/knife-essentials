require 'chef_fs/file_system/base_fs_object'

class ChefFS
  module FileSystem
    class RestListEntry < BaseFSObject
      def initialize(name, parent, exists = nil)
        super(name, parent)
        @exists = exists
      end

      def exists?
        @exists ||= parent.children.any? { |child| child.name == name }
      end

      def read
        rest.get_rest(path)
      end

      def rest
        parent.rest
      end
    end
  end
end
