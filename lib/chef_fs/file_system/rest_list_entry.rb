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
        environment ? "#{parent.api_path}/#{name}/environments/#{environment}" : "#{parent.api_path}/#{name}"
      end

      def exists?
        if @exists.nil?
          @exists = parent.children.any? { |child| child.name == name }
        end
        @exists
      end

      def local_path
        "#{path}.json"
      end

      def delete
        begin
          rest.delete_rest(api_path)
        rescue Net::HTTPServerException
          if $!.response.code == "404"
            raise ChefFS::FileSystem::NotFoundException, $!
          else
            raise
          end
        end
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
        end
      end

      def write(contents)
        rest.put_rest(api_path, contents)
      end

      def environment
        parent.environment
      end

      def rest
        parent.rest
      end
    end
  end
end
