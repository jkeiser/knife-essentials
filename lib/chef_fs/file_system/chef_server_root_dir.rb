require 'chef_fs/file_system/base_fs_dir'
require 'chef_fs/file_system/rest_list_dir'
require 'chef_fs/file_system/data_bags_dir'
require 'chef_fs/file_system/cookbooks_dir'

module ChefFS
  module FileSystem
    class ChefServerRootDir < BaseFSDir
      def initialize(config)
        super("", nil)
        @chef_server_url = config[:chef_server_url]
        @chef_username = config[:node_name]
        @chef_private_key = config[:client_key]
        @environment = config[:environment]
      end

      attr_reader :chef_server_url
      attr_reader :chef_username
      attr_reader :chef_private_key
      attr_reader :environment

      def rest
        Chef::REST.new(chef_server_url, chef_username, chef_private_key)
      end

      def api_path
        ""
      end

      def children
        @children ||= [
          RestListDir.new("clients", self),
          CookbooksDir.new(self),
          DataBagsDir.new(self),
          RestListDir.new("environments", self),
          RestListDir.new("nodes", self),
          RestListDir.new("roles", self),
  #        RestListDir.new("sandboxes", self)
        ]
      end
    end
  end
end
