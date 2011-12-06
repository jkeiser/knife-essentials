require 'chef_fs/knife'
require 'tempfile'
require 'fileutils'

class Chef
  class Knife
    class Diff < ChefFS::Knife
      banner "diff PATTERNS"

      def run
        patterns = pattern_args_from(name_args.length > 0 ? name_args : [ "" ])

        # Get the matches (recursively)
        pattern_args.each do |pattern|
          chef_fs.list(pattern).each do |result|
            diff_recursive(result)
          end
        end
      end

      def diff_recursive(result)
        if result.dir?
          if !Dir.exist?(local_path(result))
            puts "#{format_path(result.path)}: Directory is on the server but is not on the local filesystem"
          else
            begin
              result.children.each { |child| diff_recursive(child) }
            rescue ChefFS::FileSystem::NotFoundException
              puts "#{format_path(result.path)}: Directory is on the local filesystem but is not on the server"
            end
          end
        else
          begin
            value = result.read
            server_copy = Tempfile.new(result.name)
            begin
              server_tempfile = server_copy.path
              server_copy.write(Chef::JSONCompat.to_json_pretty(value).lines.map { |line| line.strip }.sort.join(""))
              server_copy.close()

              if !File.exist?(local_path(result))
                puts "#{format_path(result.path)}: File is on the server but is not on the local filesystem"
              end

              local_value = IO.read(local_path(result))
              local_copy = Tempfile.new(result.name)
              begin
                local_tempfile = local_copy.path
                local_copy.write(local_value.lines.map { |line| line.strip }.sort.join(""))
                local_copy.close()

                # TODO use a gem for this
                diff_result = `diff -u #{server_tempfile} #{local_tempfile}`
                if diff_result != ''
                  # TODO print the actual diff
                  puts "#{format_path(result.path)}: File is different between the local filesystem and the server:"
                  puts diff_result
                end
              ensure
                local_copy.unlink()
              end
            ensure
              server_copy.unlink()
            end

#            puts "#{format_path(result.path)}:"
#            output(format_for_display(result.read))
          rescue ChefFS::FileSystem::NotFoundException
            if File.exist?(local_path(result))
              puts "#{format_path(result.path)}: File is on the local filesystem but is not on the server"
            end
          end
        end
      end
    end
  end
end

