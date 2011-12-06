require 'chef_fs/file_system/base_fs_dir'
require 'chef_fs/file_system/rest_list_entry'

# TODO: take environment into account

class ChefFS
  module FileSystem
    class RestListDir < BaseFSDir
      def initialize(name, parent, api_path = nil)
        super(name, parent)
        @api_path = api_path || name
      end

      attr_reader :api_path

      def child(name)
        RestListEntry.new(name, self)
      end

      def children
        @children ||= rest.get_rest(api_path).map { |entry| RestListEntry.new(entry[0], self, true) }
      end

      def rest
        parent.rest
      end
    end
  end
end
