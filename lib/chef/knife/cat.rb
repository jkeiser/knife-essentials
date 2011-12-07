require 'chef_fs/knife'

class Chef
  class Knife
    class Cat < ChefFS::Knife
      banner "cat [PATTERN1 ... PATTERNn]"

      def run
        # Get the matches (recursively)
        pattern_args.each do |pattern|
          chef_fs.list(pattern).each do |result|
            if result.dir?
              STDERR.puts "#{format_path(result.path)}: is a directory" if pattern.exact_path
            else
              begin
                value = result.read
                puts "#{format_path(result.path)}:"
                output(format_for_display(result.read))
              rescue ChefFS::FileSystem::NotFoundException
                STDERR.puts "#{format_path(result.path)}: No such file or directory" if pattern.exact_path
              end
            end
          end
        end
      end
    end
  end
end

