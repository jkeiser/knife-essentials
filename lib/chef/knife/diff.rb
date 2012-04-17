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
          found_result = false
          common_leaves_from_pattern(pattern, chef_fs, local_fs, config[:recurse] ? nil : 1) do |chef_leaf, local_leaf|
            found_result = true
            diff_leaves(chef_leaf, local_leaf)
          end
          if !found_result && pattern.exact_path
            puts "#{pattern}: No such file or directory on remote or local"
          end
        end
      end

      def calc_checksum(value)
        Digest::MD5.hexdigest(value)
      end

      # Diff two known leaves (could be files or dirs)
      def diff_leaves(old_file, new_file)
        # If both files exist ...
        if old_file.exists? && new_file.exists?
          if old_file.dir?
            if new_file.dir?
              puts "Common subdirectories: #{old_file.path}"
            else
              puts "File #{new_file.path_for_printing} is a directory while file #{new_file.path_for_printing} is a regular file"
            end
          else
            if new_file.dir?
              puts "File #{old_file.path_for_printing} is a regular file while file #{old_file.path_for_printing} is a directory"
            else
              diff_files(old_file, new_file)
            end
          end

        # If only the old file exists ...
        elsif old_file.exists?
          if old_file.dir?
            puts "Only in #{old_file.parent.path_for_printing}: #{old_file.name}"
          else
            diff = diff_text(old_file.path_for_printing, '/dev/null', old_file.read, '')
            puts diff if diff
          end

        # If only the new file exists ...
        else
          if new_file.dir?
            puts "Only in #{new_file.parent.path_for_printing}: #{new_file.name}"
          else
            diff = diff_text('/dev/null', new_file.path_for_printing, '', new_file.read)
            puts diff if diff
          end
        end
      end

      def diff_files(old_file, new_file)
        # Short-circuit expensive comparison if a pre-calculated checksum is there
        if new_file.respond_to?(:checksum)
          if old_file.respond_to?(:checksum)
            return if new_file.checksum == old_file.checksum
          else
            return if new_file.checksum == calc_checksum(old_file.read)
          end
        elsif old_file.respond_to?(:checksum)
          return if calc_checksum(new_file.read) == old_file.checksum
        end

        old_value = old_file.read
        new_value = new_file.read
        diff = diff_text(old_file.path_for_printing, new_file.path_for_printing, old_value, new_value)
        if diff != '' && context_aware_diff(old_file, new_file, old_value, new_value)
          puts diff
        end
      end

      def diff_text(old_path, new_path, old_value, new_value)
        # Copy to tempfiles before diffing
        # TODO don't copy things that are already in files!  Or find an in-memory diff algorithm
        begin
          new_tempfile = Tempfile.new("new")
          new_tempfile.write(new_value)
          new_tempfile.close

          begin
            old_tempfile = Tempfile.new("old")
            old_tempfile.write(old_value)
            old_tempfile.close

            result = `diff -u #{old_tempfile.path} #{new_tempfile.path}`
            result = result.gsub(/^--- #{old_tempfile.path}/, "--- #{old_path}")
            result = result.gsub(/^\+\+\+ #{new_tempfile.path}/, "+++ #{new_path}")
            result
          ensure
            old_tempfile.close!
          end
        ensure
          new_tempfile.close!
        end
      end

      def context_aware_diff(old_file, new_file, old_value, new_value)
        # TODO handle errors in reading JSON
        if old_file.content_type == :json || new_file.content_type == :json
          new_value = Chef::JSONCompat.from_json(new_value).to_hash
          old_value = Chef::JSONCompat.from_json(old_value).to_hash

          diff = diff_json(old_file, new_file, old_value, new_value, "")
          #if diff.length > 0
          #  puts "#{new_file.path_for_printing}: Files are different"
          #  diff.each { |message| puts "  #{message}" }
          #end
          diff.length > 0
        else
          true
        end
      end

      def diff_json(old_file, new_file, old_file_value, new_file_value, name)
        if old_file_value.is_a? Hash
          if !new_file_value.is_a? Hash
            return [ "#{name} has type #{new_file_value.class} in #{new_file.path_for_printing} and #{old_file_value.class} in #{old_file.path_for_printing}" ]
          end

          results = []
          new_file_value.each_pair do |key, value|
            new_name = name != "" ? "#{name}.#{key}" : key
            if !old_file_value.has_key?(key)
              results << "#{new_name} exists in #{new_file.path_for_printing} but not in #{old_file.path_for_printing}"
            else
              results += diff_json(old_file, new_file, old_file_value[key], new_file_value[key], new_name)
            end
          end
          old_file_value.each_key do |key|
            new_name = name != "" ? "#{name}.#{key}" : key
            if !new_file_value.has_key?(key)
              results << "#{new_name} exists in #{old_file.path_for_printing} but not in #{new_file.path_for_printing}"
            end
          end
          return results
        end

        if new_file_value.is_a? Array
          if !old_file_value.is_a? Array
            return "#{name} has type #{new_file_value.class} in #{new_file.path_for_printing} and #{old_file_value.class} in #{old_file.path_for_printing}"
          end

          results = []
          if old_file_value.length != new_file_value.length
            results << "#{name} is length #{new_file_value.length} in #{new_file.path_for_printing}, and #{old_file_value.length} in #{old_file.path_for_printing}" 
          end
          0.upto([ new_file_value.length, old_file_value.length ].min - 1) do |i|
            results += diff_json(old_file, new_file, old_file_value[i], new_file_value[i], "#{name}[#{i}]")
          end
          return results
        end

        if new_file_value != old_file_value
          return [ "#{name} is #{new_file_value.inspect} in #{new_file.path_for_printing} and #{old_file_value.inspect} in #{old_file.path_for_printing}" ]
        end

        return []
      end

      def common_leaves_from_pattern(pattern, a_root, b_root, recurse_depth)
        # Make sure everything on the server is also on the filesystem, and diff
        a_root.list(pattern).each do |a|
          if a.exists?
            b = b_root.get(a.path)
            common_leaves(a, b, recurse_depth) do |a_leaf, b_leaf|
              yield [ a_leaf, b_leaf ]
            end
          end
        end

        # Check the outer regex pattern to see if it matches anything on the filesystem that isn't on the server
        b_root.list(pattern).each do |b|
          if b.exists?
            a = a_root.get(b.path)
            if ! a.exists?
              yield [ a, b ]
            end
          end
        end
      end

      def common_leaves(a, b, recurse_depth)
        # If they are directories, and we should recurse, do so (and do not yield them).
        # If we have children, recurse into them instead of returning ourselves.
        if recurse_depth != 0 && a.exists? && b.exists? && a.dir? && b.dir? && b.children.length
          a.children.each do |a_child|
            common_leaves(a_child, b.get(a_child.name), recurse_depth ? recurse_depth - 1 : nil) do |a_leaf, b_leaf|
              yield [ a_leaf, b_leaf ]
            end
          end

          # Check b for children that aren't in a
          b.children.each do |b_child|
            a_child = a.get(b_child.path)
            if !a_child.exists?
              yield [ a_child, b_child ]
            end
          end
          return
        end

        # Otherwise, these are the leaves we must diff
        yield [a, b]
      end
    end
  end
end

