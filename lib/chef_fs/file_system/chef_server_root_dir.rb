require 'chef_fs/file_system/base_fs_dir'
require 'chef_fs/file_system/rest_list_dir'
require 'chef_fs/file_system/data_bags_dir'

class ChefFS
  module FileSystem
    class ChefServerRootDir < BaseFSDir
      def initialize(config)
        super("", nil)
        @chef_server_url = config[:chef_server_url]
        @environment = config[:environment]
      end

      attr_reader :chef_server_url
      attr_reader :environment

      def rest
        Chef::REST.new(chef_server_url)
      end

      def api_path
        ""
      end

      def children
        @children ||= [
          RestListDir.new("clients", self),
          RestListDir.new("cookbooks", self),
          DataBagsDir.new(self),
          RestListDir.new("environments", self),
          RestListDir.new("nodes", self),
          RestListDir.new("roles", self),
  #        RestListDir.new("sandboxes", self),
  #        RestListDir.new("users", self)
        ]
      end
    end
  end
end
