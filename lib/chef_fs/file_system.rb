require 'chef_fs/path_utils'

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
  end
end

