require 'chef_fs/file_system/base_fs_object'
require 'chef_fs/file_system/not_found_exception'
# TODO: these are needed for rest.get_rest() to work.  This seems strange.
require 'chef/role'
require 'chef/node'

# TODO: take environment into account
class ChefFS
  module FileSystem
    class RestListEntry < BaseFSObject
      def initialize(name, parent, exists = nil)
        super(name, parent)
        @exists = exists
      end

      def api_path
        "#{parent.api_path}/#{name}"
      end

      def exists?
        @exists ||= parent.children.any? { |child| child.name == name }
      end

      def read
        begin
          rest.get_rest(api_path)
        rescue Net::HTTPServerException
          if $!.response.code == "404"
            raise ChefFS::FileSystem::NotFoundException, $!
          else
            raise
          end
        rescue
          puts $!.inspect
        end
      end

      def rest
        parent.rest
      end
    end
  end
end
