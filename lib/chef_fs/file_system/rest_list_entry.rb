require 'chef_fs/file_system/base_fs_object'
require 'chef_fs/file_system/not_found_exception'
# TODO: these are needed for rest.get_rest() to work.  This seems strange.
require 'chef/role'
require 'chef/node'

# TODO: take environment into account
module ChefFS
  module FileSystem
    class RestListEntry < BaseFSObject
      def initialize(name, parent, exists = nil)
        super(name, parent)
        @exists = exists
      end

      def api_path
        if name.length < 5 && name[-5,5] != ".json"
          raise "Invalid name #{name}: must include .json"
        end
        api_child_name = name[0,name.length-5]
        environment ? "#{parent.api_path}/#{api_child_name}/environments/#{environment}" : "#{parent.api_path}/#{api_child_name}"
      end

      def environment
        parent.environment
      end

      def exists?
        if @exists.nil?
          @exists = parent.children.any? { |child| child.name == name }
        end
        @exists
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
          Chef::JSONCompat.to_json_pretty(rest.get_rest(api_path).to_hash)
        rescue Net::HTTPServerException
          if $!.response.code == "404"
            raise ChefFS::FileSystem::NotFoundException, $!
          else
            raise
          end
        end
      end

      def rest
        parent.rest
      end

      def content_type
        :json
      end

      def write(contents)
        rest.put_rest(api_path, contents)
      end
    end
  end
end
