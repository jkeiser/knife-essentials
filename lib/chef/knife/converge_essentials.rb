require 'chef_fs/knife'

class Chef
  class Knife
    remove_const(:Converge) if const_defined?(:Converge) && Converge.name == 'Chef::Knife::Converge' # override Chef's version
    class Converge < ::ChefFS::Knife
      ChefFS = ::ChefFS
      banner "knife converge [PATTERN1 ... PATTERNn]"

      deps do
        begin
          require 'chef_zero/server'
        rescue LoadError
          STDERR.puts <<EOM
ERROR: chef-zero must be installed to run "knife serve"!  To install:

    gem install chef-zero

EOM
          exit(1)
        end
        require 'chef_fs/chef_fs_data_store'
        require 'chef/log'
        require 'chef/application/client'
      end

      option :port,
        :short => '-p',
        :long => '--port=PORT',
        :description => "Port to listen on (default: 8889)"

      def configure_chef
        super

        if config[:config_file]
          dot_chef = File.dirname(config[:config_file])
          if File.basename(dot_chef) == '.chef'
            # Override default locations to go in the .chef directory, since we are knife.
            Chef::Config[:client_key] = File.join(dot_chef, 'client.pem') if !Chef::Config[:client_key] || Chef::Config[:client_key] == Chef::Config.platform_specific_path("/etc/chef/client.pem")
            Chef::Config[:file_cache_path] = File.join(dot_chef, 'cache') if Chef::Config[:file_cache_path] == Chef::Config.platform_specific_path("/var/chef/cache")
            Chef::Config[:file_backup_path] = File.join(dot_chef, 'backups') if Chef::Config[:file_backup_path] == Chef::Config.platform_specific_path("/var/chef/backup")
            Chef::Config[:file_checksum_path] = File.join(dot_chef, 'checksums') if Chef::Config[:file_checksum_cache] == "/var/chef/checksums"
          end
        end
      end

      def run
        run_chef_client
      end

      def run_chef_client
        client = Chef::Application::Client.new
        client.configure_logging # Bypass configure_chef, which we've already done adequately.
        client.setup_application
        client.run_application
      end
    end
  end
end
