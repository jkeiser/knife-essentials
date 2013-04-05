require 'chef_fs/knife'
require 'chef_fs/file_system'
require 'chef_fs/file_system/not_found_error'
require 'deep_merge'


class Chef
  class Knife
    remove_const(:BulkEdit) if const_defined?(:BulkEdit) && BulkEdit.name == 'Chef::Knife::BulkEdit' # override Chef's version
    class BulkEdit < ::ChefFS::Knife
      ChefFS = ::ChefFS
      banner "knife bulk edit [PATTERN1 ... PATTERNn]"

      common_options

      option :local,
        :long => '--local',
        :boolean => true,
        :description => "Show local files instead of remote"

      option :json_filename,
        :long => '--json FILENAME',
        :short => '-j FILENAME',
        :default => {},
        :description => "Path to the file with the changes"

      def run
        # Get the matches (recursively)
        error = false
        if config[:json_filename] != {}
          open(config[:json_filename]) {|f|
          @changes = f.read
          }
        end
        changes_json = JSON.parse(@changes, :create_additions => false)
        pattern_args.each do |pattern|
          ChefFS::FileSystem.list(config[:local] ? local_fs : chef_fs, pattern) do |result|
            if result.dir?
              ui.error "#{format_path(result)}: is a directory" if pattern.exact_path
              error = true
            else
              begin
                  value = result.read
                  orig = JSON.parse(value, :create_additions => false)
                  orig_dup = orig.dup
                  new_file = DeepMerge::deep_merge!(changes_json, orig)
                  if(orig_dup != new_file)
                    output "#{format_path(result)}: Uploading to the server"
                    result.write(new_file.to_json)
                  else
                    output "#{format_path(result)}: The file on the server already has the changes, hence not uploading."
                  end
                rescue ChefFS::FileSystem::OperationNotAllowedError => e
                  ui.error "#{format_path(e.entry)}: #{e.reason}."
                  error = true
                rescue ChefFS::FileSystem::NotFoundError => e
                  ui.error "#{format_path(e.entry)}: No such file or directory"
                  error = true
                end
              end
            end
          end
        if error
          exit 1
        end
      end
    end
  end
end
