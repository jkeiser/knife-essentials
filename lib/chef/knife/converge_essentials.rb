require 'chef_fs/knife'
require 'chef/application/client'

class Chef
  class Knife
    remove_const(:Converge) if const_defined?(:Converge) && Converge.name == 'Chef::Knife::Converge' # override Chef's version
    class Converge < ::ChefFS::Knife
      ChefFS = ::ChefFS
      banner "knife converge [PATTERN1 ... PATTERNn]"

      deps do
        require 'chef'
        require 'chef/log'
        require 'chef_fs/file_system'
      end

      options.merge!(Chef::Application::Client.options)

      option :port,
        :short => '-p',
        :long => '--port=PORT',
        :description => "Port to listen on (default: 8889)"

      attr_accessor :exit_code

      def configure_chef
        super

        if config[:config_file]
          ui.output "Using config file #{config[:config_file]} ..."
        end

        Chef::Config.merge!(config)

        self.exit_code = 0
      end

      def run
        # Figure out the run list based on the passed-in objects
        run_list = get_run_list(name_args)

        if exit_code != 0
          exit exit_code
        end

        # Configure and run chef client
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
        client = Chef::Application::Client.new
        client.config = config
        if run_list != ''
          client.config[:override_runlist] = run_list
        end
        client.configure_logging # Bypass configure_chef, which we've already done adequately.
        client.setup_application
        client.run_application
      end

      def get_run_list(args)
        result = []
        args.each do |arg|
          if arg.start_with?('recipe[') || arg.start_with?('role[')
            result += arg.split(',')

          else
            begin
              ChefFS::FileSystem.list(chef_fs, pattern_arg_from(arg)).each do |entry|
                if entry.parent && entry.parent.path == '/cookbooks'
                  result << "recipe[#{entry.name}]"

                elsif entry.parent && entry.parent.name == 'recipes' &&
                      entry.parent.parent && entry.parent.parent.parent && entry.parent.parent.parent.name == 'cookbooks' &&
                      entry.name[-3..-1] == '.rb'
                  cookbook_name = entry.parent.parent.name
                  recipe_name = entry.name[0..-4]
                  result << "recipe[#{cookbook_name}::#{recipe_name}]"

                elsif entry.parent && entry.parent.name == 'roles'
                  result << "role[#{entry.name}]"

                else
                  ui.error "arguments must be cookbooks, recipes or roles!  #{format_path(entry)} is not a cookbook, recipe or role."
                  self.exit_code = 1
                end
              end
            rescue ChefFS::FileSystem::OperationFailedError => e
              "#{format_path(e.entry)} #{e.reason}."
              self.exit_code = 1
            rescue ChefFS::FileSystem::NotFoundError => e
              ui.error "#{format_path(e.entry)}: No such file or directory"
              self.exit_code = 1
            end
          end
        end
        result.join(',')
      end
    end
  end
end
