require 'chef_fs/knife'
require 'chef/json_compat'
require 'tempfile'
require 'fileutils'

class Chef
  class Knife
    class Diff < ChefFS::Knife
      banner "diff PATTERNS"

      def run
        patterns = pattern_args_from(name_args.length > 0 ? name_args : [ "" ])

        # Get the matches (recursively)
        patterns.each do |pattern|
          # Make sure everything on the server is also on the filesystem, and diff
          results = chef_fs.list(pattern)
          results.each do |result|
            diff_recursive(result)
          end

          # Look for things on the filesystem that are not also on the server
          puts local_pattern(pattern)
          Dir.glob(local_pattern(pattern)).each do |file|
            if !results.any? { |result| result.path == relative_to(file, chef_repo) }
              if File.is_directory?(file)
                puts "Directory #{file} exists on the local filesystem but is not on the server"
              else
                puts "File #{file} exists on the local filesystem but is not on the server"
              end
            end
          end
        end
      end

      def diff_recursive(result)
        if result.dir?
          # If it's a directory, check for existence and recurse
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
          # If it's a file, diff the files
          begin
            value = result.read
            begin
              local_value = Chef::JSONCompat.from_json(IO.read(local_path(result)))
              diff = diff_json(value, local_value, "doc")
              if diff.length > 0
                puts "#{format_path(result.path)}: Files are different"
                diff.each { |message| puts "  #{message}" }
              end
            rescue Errno::ENOENT # TODO Also catch case where file is a directory
              puts "#{format_path(result.path)}: File is on the server but is not on the local filesystem"
            end
          rescue ChefFS::FileSystem::NotFoundException
            if File.exist?(local_path(result))
              puts "#{format_path(result.path)}: File is on the local filesystem but is not on the server"
            end
          end
        end
      end

      def saved_proc
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
      end

      def diff_json(server, local, name)
        if server == nil
          return [ "#{name} exists on the server but not locally" ]
        end
        if local == nil
          return [ "#{name} exists locally but not on the server" ]
        end
        if server.is_a? Hash
          if !local.is_a? Hash
            return [ "#{name} has type #{server.class} on the server and #{local.class} locally" ]
          end

          results = []
          server.each_pair do |key, value|
            new_name = "#{name}.#{key}"
            if !local.has_key?(key)
              results << "#{new_name} exists on the server but not locally"
            else
              results += diff_json(server[key], local[key], new_name)
            end
          end
          local.each_key do |key|
            new_name = "#{name}.#{key}"
            if !server.has_key?(key)
              results << "#{new_name} exists locally but not on the server"
            end
          end
          return results
        end

        if server.is_a? Array
          if !local.is_a? Array
            return "#{name} has type #{server.class} on the server and #{local.class} locally"
          end

          results = []
          if local.length != server.length
            results << "#{name} is length #{server.length} on the server, and #{local.length} locally" 
          end
          0.upto([ server.length, local.length ].min - 1) do |i|
            results += diff_json(server[i], local[i], "#{name}[#{i}]")
          end
          return results
        end

        if server != local
          return [ "#{name} is #{server.inspect} on the server and #{local.inspect} locally" ]
        end

        return []
      end
    end
  end
end

