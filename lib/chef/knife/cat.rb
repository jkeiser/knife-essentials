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
              STDERR.puts "cat: #{pattern}: is a directory" if pattern.exact_path
            else
              begin
                value = result.read
                puts "#{format_path(result.path)}:"
                output(format_for_display(result.read))
              rescue ChefFS::FileSystem::NotFoundException
                STDERR.puts "cat: #{pattern}: file not found" if pattern.exact_path
              end
            end
          end
        end
      end
    end
  end
end

