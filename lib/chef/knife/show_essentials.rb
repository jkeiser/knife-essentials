require 'chef_fs/knife'
require 'chef_fs/file_system'

class Chef
  class Knife
    remove_const(:Show) if const_defined?(:Show) && Show.name == 'Chef::Knife::Show' # override Chef's version
    class Show < ::ChefFS::Knife
      ChefFS = ::ChefFS
      banner "knife show [PATTERN1 ... PATTERNn]"

      common_options

      option :local,
        :long => '--local',
        :boolean => true,
        :description => "Show local files instead of remote"

      def run
        # Get the matches (recursively)
        pattern_args.each do |pattern|
          ChefFS::FileSystem.list(config[:local] ? local_fs : chef_fs, pattern) do |result|
            if result.dir?
              ui.error "#{result.path_for_printing}: is a directory" if pattern.exact_path
            else
              begin
                value = result.read
                output "#{result.path_for_printing}:"
                output(format_for_display(value))
              rescue ChefFS::FileSystem::NotFoundError => e
                ui.error "#{e.entry.path_for_printing}: No such file or directory"
              end
            end
          end
        end
      end
    end
  end
end

