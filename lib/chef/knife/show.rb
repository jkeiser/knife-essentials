require 'chef_fs/knife'
require 'chef_fs/file_system'

class Chef
  class Knife
    class Show < ChefFS::Knife
      banner "show [PATTERN1 ... PATTERNn]"

      def run
        # Get the matches (recursively)
        pattern_args.each do |pattern|
          ChefFS::FileSystem.list(chef_fs, pattern) do |result|
            if result.dir?
              STDERR.puts "#{format_path(result.path)}: is a directory" if pattern.exact_path
            else
              begin
                value = result.read
                puts "#{format_path(result.path)}:"
                output(format_for_display(result.read))
              rescue ChefFS::FileSystem::NotFoundError
                STDERR.puts "#{format_path(result.path)}: No such file or directory" if pattern.exact_path
              end
            end
          end
        end
      end
    end
  end
end

