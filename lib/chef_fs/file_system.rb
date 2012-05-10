require 'chef_fs/path_utils'
require 'chef_fs/diff'

module ChefFS
  module FileSystem
    # Yields a list of all things under (and including) this entry that match the
    # given pattern.
    #
    # ==== Attributes
    #
    # * +entry+ - Entry to start listing under
    # * +pattern+ - ChefFS::FilePattern to match children under
    #
    def self.list(entry, pattern, &block)
      # Include self in results if it matches
      if pattern.match?(entry.path)
        block.call(entry)
      end

      if entry.dir? && pattern.could_match_children?(entry.path)
        # If it's possible that our children could match, descend in and add matches.
        exact_child_name = pattern.exact_child_name_under(entry.path)

        # If we've got an exact name, don't bother listing children; just grab the
        # child with the given name.
        if exact_child_name
          exact_child = entry.child(exact_child_name)
          if exact_child
            list(exact_child, pattern, &block)
          end

        # Otherwise, go through all children and find any matches
        else
          entry.children.each do |child|
            list(child, pattern, &block)
          end
        end
      end
    end

    # Resolve the given path against the entry, returning
    # the entry at the end of the path.
    #
    # ==== Attributes
    #
    # * +entry+ - the entry to start looking under.  Relative
    #   paths will be resolved from here.
    # * +path+ - the path to resolve.  If it starts with +/+,
    #   the path will be resolved starting from +entry.root+.
    #
    # ==== Examples
    #
    #     ChefFS::FileSystem.resolve_path(root_path, 'cookbooks/java/recipes/default.rb')
    #
    def self.resolve_path(entry, path)
      return entry if path.length == 0
      return resolve_path(entry.root, path) if path[0] == "/" && entry.root != entry
      if path[0] == "/"
        path = path[1,path.length-1]
      end

      result = entry
      ChefFS::PathUtils::split(path).each do |part|
        result = result.child(part)
      end
      result
    end

    # Copy everything matching the given pattern from src to dest.
    #
    # After this method completes, everything in dest matching the
    # given pattern will look identical to src.
    #
    # ==== Attributes
    #
    # * +pattern+ - ChefFS::FilePattern to match children under
    # * +src_root+ - the root from which things will be copied
    # * +dest_root+ - the root to which things will be copied
    # * +recurse_depth+ - the maximum depth to copy things. +nil+
    #   means infinite depth.  0 means no recursion.
    # * +purge+ - if +true+, items in +dest+ that are not in +src+
    #   will be deleted from +dest+.  If +false+, these items will
    #   be left alone.
    #
    # ==== Examples
    #
    #     ChefFS::FileSystem.copy_to(FilePattern.new('/cookbooks', chef_fs, local_fs, nil, true)
    #
    def self.copy_to(pattern, src_root, dest_root, recurse_depth, purge)
      found_result = false
      # Find things we might want to copy
      ChefFS::Diff::diffable_leaves_from_pattern(pattern, src_root, dest_root, recurse_depth) do |src_leaf, dest_leaf, child_recurse_depth|
        found_result = true
        copy_leaves(src_leaf, dest_leaf, child_recurse_depth, purge)
      end
      if !found_result && pattern.exact_path
        yield "#{pattern}: No such file or directory on remote or local"
      end
    end

    private

    # Copy two known leaves (could be files or dirs)
    def self.copy_leaves(src_entry, dest_entry, recurse_depth, purge)
      # A NOTE about this algorithm:
      # There are cases where this algorithm does too many network requests.
      # knife upload with a specific filename will first check if the file
      # exists (a "dir" in the parent) before deciding whether to POST or
      # PUT it.  If we just tried PUT (or POST) and then tried the other if
      # the conflict failed, we wouldn't need to check existence.
      # On the other hand, we may already have DONE the request, in which
      # case we shouldn't waste time trying PUT if we know the file doesn't
      # exist.
      # Will need to decide how that works with checksums, though.

      if !src_entry.exists?
        if purge
          # If we would not have uploaded it, we will not purge it.
          if src_entry.parent.can_have_child?(dest_entry.name, dest_entry.dir?)
            dest_entry.delete
            puts "Delete extra entry #{dest_entry.path_for_printing} (purge is on)"
          else
            Chef::Log.info("Not deleting extra entry #{dest_entry.path_for_printing} (purge is off)")
          end
        end

      elsif !dest_entry.exists?
        if dest_entry.parent.can_have_child?(src_entry.name, src_entry.dir?)
          if src_entry.dir?
            new_dest_dir = dest_entry.parent.create_child(src_entry.name, nil)
            puts "Created #{dest_entry.path_for_printing}/"
            # Directory creation is recursive.
            if recurse_depth != 0
              src_entry.children.each do |src_child|
                new_dest_child = new_dest_dir.child(src_child.name)
                copy_leaves(src_child, new_dest_child, recurse_depth ? recurse_depth - 1 : recurse_depth, purge)
              end
            end
          else
            dest_entry.parent.create_child(src_entry.name, src_entry.read)
            puts "Created #{dest_entry.path_for_printing}"
          end
        end

      else
        # Both exist.
        # If they are different types, log an error.
        if src_entry.dir?
          if dest_entry.dir?
            # If they are both directories, we'll end up recursing later.
          else
            # If they are different types.
            Chef::Log.error("File #{dest_entry.path_for_printing} is a directory while file #{dest_entry.path_for_printing} is a regular file\n")
            return
          end
        else
          if dest_entry.dir?
            Chef::Log.error("File #{dest_entry.path_for_printing} is a directory while file #{dest_entry.path_for_printing} is a regular file\n")
            return
          else
            # Both are files!  Copy them unless we're sure they are the same.
            different, src_value, dest_value = ChefFS::Diff.diff_files_quick(src_entry, dest_entry)
            if different || different == nil
              src_value = src_entry.read if src_value == :not_retrieved
              dest_entry.write(src_value)
              puts "Updated #{dest_entry.path_for_printing}"
            end
          end
        end
      end
    end

  end
end

