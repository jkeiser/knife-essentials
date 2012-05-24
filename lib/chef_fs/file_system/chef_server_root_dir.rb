require 'chef_fs/file_system/base_fs_dir'
require 'chef_fs/file_system/rest_list_dir'
require 'chef_fs/file_system/cookbooks_dir'
require 'chef_fs/file_system/data_bags_dir'
require 'chef_fs/file_system/nodes_dir'

module ChefFS
  module FileSystem
    class ChefServerRootDir < BaseFSDir
      def initialize(root_name, chef_config, repo_mode)
        super("", nil)
        @chef_server_url = chef_config[:chef_server_url]
        @chef_username = chef_config[:node_name]
        @chef_private_key = chef_config[:client_key]
        @environment = chef_config[:environment]
        @repo_mode = repo_mode
        @root_name = root_name
      end

      attr_reader :chef_server_url
      attr_reader :chef_username
      attr_reader :chef_private_key
      attr_reader :environment
      attr_reader :repo_mode

      def rest
        Chef::REST.new(chef_server_url, chef_username, chef_private_key)
      end

      def api_path
        ""
      end

      def path_for_printing
        "#{@root_name}/"
      end

      def can_have_child?(name, is_dir)
        is_dir && children.any? { |child| child.name == name }
      end

      def children
        @children ||= begin
          result = [
            CookbooksDir.new(self),
            DataBagsDir.new(self),
            RestListDir.new("environments", self),
            RestListDir.new("roles", self)
          ]
          if repo_mode == 'everything'
            result += [
              RestListDir.new("clients", self),
              NodesDir.new(self),
              RestListDir.new("users", self)
            ]
          end
          result.sort_by { |child| child.name }
        end
      end

      # Yeah, sorry, I'm not putting delete on this thing.
    end
  end
end
