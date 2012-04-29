require 'chef_fs/file_system'
require 'chef/json_compat'
require 'tempfile'
require 'fileutils'
require 'digest/md5'
require 'set'

module ChefFS
  class Diff
    def self.calc_checksum(value)
      return nil if value == nil
      Digest::MD5.hexdigest(value)
    end

    def self.diff_files_quick(old_file, new_file)
      #
      # Short-circuit expensive comparison (could be an extra network
      # request) if a pre-calculated checksum is there
      #
      if new_file.respond_to?(:checksum)
        new_checksum = new_file.checksum
      end
      if old_file.respond_to?(:checksum)
        old_checksum = old_file.checksum
      end

      old_value = :not_retrieved
      new_value = :not_retrieved

      if old_checksum || new_checksum
        if !old_checksum
          old_value = read_file_value(old_file)
          if old_value
            old_checksum = calc_checksum(old_value)
          end
        end
        if !new_checksum
          new_value = read_file_value(new_file)
          if new_value
            new_checksum = calc_checksum(new_value)
          end
        end

        # If the checksums are the same, they are the same.  Return.
        return [ false, old_value, new_value ] if old_checksum == new_checksum
      end

      return [ nil, old_value, new_value ]
    end

    def self.diff_files(old_file, new_file)
      different, old_value, new_value = diff_files_quick(old_file, new_file)
      if different != nil
        return different
      end

      #
      # Grab the values if we don't have them already from calculating checksum
      #
      old_value = read_file_value(old_file) if old_value == :not_retrieved
      new_value = read_file_value(new_file) if new_value == :not_retrieved

      return false if old_value == new_value
      return false if old_value && new_value && context_aware_diff(old_file, new_file, old_value, new_value) == false
      return [ true, old_value, new_value ]
    end

    def self.context_aware_diff(old_file, new_file, old_value, new_value)
      if old_file.content_type == :json || new_file.content_type == :json
        begin
          new_value = Chef::JSONCompat.from_json(new_value).to_hash
          old_value = Chef::JSONCompat.from_json(old_value).to_hash
          return old_value != new_value
        rescue JSON::ParserError
        end
      end
      return nil
    end

    # Gets all common leaves, recursively, starting from the results of
    # a pattern search on two roots.
    #
    # ==== Attributes
    #
    # * +pattern+ - a ChefFS::FilePattern representing the search you want to
    #   do on both roots.
    # * +a_root+ - the first root.
    # * +b_root+ - 
    # * +recurse_depth+ - the maximum number of directories to recurse from each
    #   pattern result.  +0+ will cause pattern results to be immediately returned.
    #   +nil+ means recurse infinitely to find all leaves.
    #
    def self.diffable_leaves_from_pattern(pattern, a_root, b_root, recurse_depth)
      # Make sure everything on the server is also on the filesystem, and diff
      found_paths = Set.new
      ChefFS::FileSystem.list(a_root, pattern) do |a|
        found_paths << a.path
        b = ChefFS::FileSystem.resolve_path(b_root, a.path)
        diffable_leaves(a, b, recurse_depth) do |a_leaf, b_leaf, leaf_recurse_depth|
          yield [ a_leaf, b_leaf, leaf_recurse_depth ]
        end
      end

      # Check the outer regex pattern to see if it matches anything on the
      # filesystem that isn't on the server
      ChefFS::FileSystem.list(b_root, pattern) do |b|
        if !found_paths.include?(b.path)
          a = ChefFS::FileSystem.resolve_path(a_root, b.path)
          yield [ a, b, recurse_depth ]
        end
      end
    end

    # Gets all common leaves, recursively, from a pair of directories or files.  It
    # recursively descends into all children of +a+ and +b+, yielding equivalent
    # pairs (common children with the same name) when it finds:
    # * +a+ or +b+ is not a directory.
    # * Both +a+ and +b+ are empty.
    # * It reaches +recurse_depth+ depth in the tree.
    #
    # This method will *not* check whether files exist, nor will it actually diff
    # the contents of files.
    #
    # ==== Attributes
    #
    # +a+ - the first directory to recursively scan
    # +b+ - the second directory to recursively scan, in tandem with +a+
    # +recurse_depth - the maximum number of directories to go down.  +0+ will
    # cause +a+ and +b+ to be immediately returned.  +nil+ means recurse
    # infinitely.
    #
    def self.diffable_leaves(a, b, recurse_depth)
      # If both are directories, recurse into them and diff the children instead of returning ourselves.
      if recurse_depth != 0 && a.dir? && b.dir?
        a_children_names = Set.new
        a.children.each do |a_child|
          a_children_names << a_child.name
          diffable_leaves(a_child, b.child(a_child.name), recurse_depth ? recurse_depth - 1 : nil) do |a_leaf, b_leaf, leaf_recurse_depth|
            yield [ a_leaf, b_leaf, leaf_recurse_depth ]
          end
        end

        # Check b for children that aren't in a
        b.children.each do |b_child|
          if !a_children_names.include?(b_child.name)
            yield [ a.child(b_child.name), b_child, recurse_depth ]
          end
        end
        return
      end

      # Otherwise, this is a leaf we must diff.
      yield [a, b]
    end

    private

    def self.read_file_value(file)
      begin
        return file.read
      rescue ChefFS::FileSystem::NotFoundError
        return nil
      end
    end
  end
end

