require 'chef_fs/knife'
require 'chef_fs/file_system'
require 'chef_fs/file_system/not_found_error'

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
        error = false
        entry_values = parallelize(pattern_args, :flatten => true) do |pattern|
          parallelize(ChefFS::FileSystem.list(config[:local] ? local_fs : chef_fs, pattern)) do |entry|
            if entry.dir?
              ui.error "#{format_path(entry)}: is a directory" if pattern.exact_path
              error = true
              nil
            else
              begin
                [entry, entry.read]
              rescue ChefFS::FileSystem::OperationNotAllowedError => e
                ui.error "#{format_path(e.entry)}: #{e.reason}."
                error = true
                nil
              rescue ChefFS::FileSystem::NotFoundError => e
                ui.error "#{format_path(e.entry)}: No such file or directory"
                error = true
                nil
              end
            end
          end
        end
        entry_values.each do |entry, value|
          if entry
            output "#{format_path(entry)}:"
            output(format_for_display(value))
          end
        end
        if error
          exit 1
        end
      end
    end
  end
end

