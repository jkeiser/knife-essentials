require 'chef_fs/file_system/base_fs_dir'
require 'chef_fs/file_system/rest_list_entry'
require 'chef_fs/file_system/not_found_error'

module ChefFS
  module FileSystem
    class NodesDir < RestListDir
      def initialize(parent)
        super("nodes", parent)
      end

      # Override children to respond to environment
      def children
        @children ||= begin
          env_api_path = environment ? "environments/#{environment}/#{api_path}" : api_path
          rest.get_rest(env_api_path).keys.map { |key| RestListEntry.new("#{key}.json", self, true) }
        rescue Net::HTTPServerException
          if $!.response.code == "404"
            raise ChefFS::FileSystem::NotFoundError.new($!), "#{path_for_printing} not found"
          else
            raise
          end
        end
    end
    end
  end
end
