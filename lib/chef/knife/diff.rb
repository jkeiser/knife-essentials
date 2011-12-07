require 'chef_fs/knife'
require 'chef/json_compat'
require 'tempfile'
require 'fileutils'
require 'digest/md5'

class Chef
  class Knife
    class Diff < ChefFS::Knife
      banner "diff PATTERNS"

      option :recurse,
        :long => '--[no-]recurse',
        :boolean => true,
        :default => true,
        :description => "List directories recursively."

      def run
        patterns = pattern_args_from(name_args.length > 0 ? name_args : [ "" ])

        # Get the matches (recursively)
        patterns.each do |pattern|
          # Make sure everything on the server is also on the filesystem, and diff
          results = chef_fs.list(pattern)
          results.each do |result|
            diff(result, config[:recurse] ? nil : 1, pattern)
          end

          # Check the outer regex pattern to see if it matches anything on the filesystem that isn't on the server
          local_fs.list(pattern).each do |local|
            if !results.any? { |result| result.path == local.path }
              puts "#{format_path(local.path)}: #{local.dir? ? "Directory" : "File"} is on the local filesystem but is not on the server"
            end
          end
        end
      end

      def calc_checksum(value)
        Digest::MD5.hexdigest(value.read)
      end

      def diff(result, recurse_depth, pattern)
        local = local_fs.get(result.path)
        # Make sure local version exists.  We check the existence of the remote version by reading from it.
        if !local.exists?
          if result.exists?
            puts "#{format_path(result.path)}: #{result.dir? ? "Directory" : "File"} is on the server but is not on the local filesystem"
          else
            puts "#{format_path(result.path)}: No such file or directory" if pattern.exact_path
          end
          return
        end

        if result.dir?
          # If it's a directory, recurse to children
          if recurse_depth != 0
            begin
              result.children.each { |child| diff(child, recurse_depth ? recurse_depth - 1 : nil, pattern) }
              # Check for children on the filesystem that are not on the server
              local.children.each do |child|
                if !result.children.any? { |result_child| result_child.path == child.path }
                  puts "#{format_path(child.path)}: #{child.dir? ? "Directory" : "File"} is on the local filesystem but is not on the server"
                end
              end
            rescue ChefFS::FileSystem::NotFoundException
              puts "#{format_path(result.path)}: #{local.dir? ? "Directory" : "File"} is on the local filesystem but is not on the server"
            end
          elsif !result.exists?
            puts "#{format_path(result.path)}: #{local.dir? ? "Directory" : "File"} is on the local filesystem but is not on the server"
          end

        else
          # If it's a file, diff the files

          # Short-circuit expensive comparison if a pre-calculated checksum is there
          if result.respond_to?(:checksum)
            if local.respond_to?(:checksum)
              return if result.checksum == local.checksum
            else
              return if result.checksum == calc_checksum(local)
            end
          elsif local.respond_to?(:checksum)
            return if calc_checksum(result) == local.checksum
          end

          # Grab the result for diffage
          begin
            value = result.read
          rescue ChefFS::FileSystem::NotFoundException
            puts "#{format_path(result.path)}: File is on the local filesystem but is not on the server"
            return
          end
          local_value = local.read

          # Perform the actual compare (JSON-sensitive if JSON)
          if result.content_type == :json || local.content_type == :json
            value = Chef::JSONCompat.from_json(value) if result.content_type == :text
            local_value = Chef::JSONCompat.from_json(local_value) if local.content_type == :text
            value = value.to_hash if value.respond_to? :to_hash
            local_value = local_value.to_hash if local_value.respond_to? :to_hash

            diff = diff_json(value, local_value, "")
            if diff.length > 0
              puts "#{format_path(result.path)}: Files are different"
              diff.each { |message| puts "  #{message}" }
            end
          else
            diff = diff_text(result, local, value, local_value)
            if diff != ''
              puts "#{format_path(result.path)}: Files are different"
              puts diff
            end
          end
        end
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
            new_name = name != "" ? "#{name}.#{key}" : key
            if !local.has_key?(key)
              results << "#{new_name} exists on the server but not locally"
            else
              results += diff_json(server[key], local[key], new_name)
            end
          end
          local.each_key do |key|
            new_name = name != "" ? "#{name}.#{key}" : key
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

      def diff_text(server, local, server_value, local_value)
        begin
          server_file = Tempfile.new("server")
          server_file.write(server_value)
          server_file.close

          begin
            local_file = Tempfile.new("local")
            local_file.write(local_value)
            local_file.close

            result = `diff -u #{server_file.path} #{local_file.path}`
            result = result.gsub(/^--- #{server_file.path}/, "--- SERVER:#{server.path}")
            result = result.gsub(/^\+\+\+ #{local_file.path}/, "--- LOCAL:#{local.path}")
            result
          ensure
            local_file.close!
          end
        ensure
          server_file.close!
        end
      end
    end
  end
end

