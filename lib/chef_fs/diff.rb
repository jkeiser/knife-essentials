require 'chef_fs/file_system'
require 'chef/json_compat'
require 'tempfile'
require 'fileutils'
require 'digest/md5'
require 'set'

module ChefFS
  class Diff
    def self.calc_checksum(value)
      Digest::MD5.hexdigest(value)
    end

    def self.diff_files(old_file, new_file)
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
      if diff == ''
        return nil
      end
      if !context_aware_diff(old_file, new_file, old_value, new_value)
        return nil
      end

      return diff
    end

    def self.diff_text(old_path, new_path, old_value, new_value)
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

    def self.context_aware_diff(old_file, new_file, old_value, new_value)
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

    def self.diff_json(old_file, new_file, old_file_value, new_file_value, name)
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

    def self.diffable_leaves_from_pattern(pattern, a_root, b_root, recurse_depth)
      # Make sure everything on the server is also on the filesystem, and diff
      found_paths = Set.new
      ChefFS::FileSystem.list(a_root, pattern).each do |a|
        found_paths << a.path
        b = ChefFS::FileSystem.get_path(b_root, a.path)
        diffable_leaves(a, b, recurse_depth) do |a_leaf, b_leaf|
          yield [ a_leaf, b_leaf ]
        end
      end

      # Check the outer regex pattern to see if it matches anything on the filesystem that isn't on the server
      ChefFS::FileSystem.list(b_root, pattern).each do |b|
        if !found_paths.include?(b.path)
          a = ChefFS::FileSystem.get_path(a_root, b.path)
          yield [ a, b ]
        end
      end
    end

    def self.diffable_leaves(a, b, recurse_depth)
      # If we have children, recurse into them and diff the children instead of returning ourselves.
      if recurse_depth != 0 && a.dir? && b.dir? && a.children.length > 0 && b.children.length > 0
        a.children.each do |a_child|
          diffable_leaves(a_child, b.child(a_child.name), recurse_depth ? recurse_depth - 1 : nil) do |a_leaf, b_leaf|
            yield [ a_leaf, b_leaf ]
          end
        end

        # Check b for children that aren't in a
        b.children.each do |b_child|
          if !a.children.any? { a_child.name == b_child.name }
            yield [ a_child, b_child ]
          end
        end
        return
      end

      # Otherwise, this is a leaf we must diff.
      yield [a, b]
    end
  end
end

