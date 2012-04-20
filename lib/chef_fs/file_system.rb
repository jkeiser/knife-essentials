require 'chef_fs/path_utils'

module ChefFS
  module FileSystem
    # Get a list of all things under (and including) this entry that match the given pattern
    def self.list(entry, pattern)
      result = []

      # Include self in results if it matches
      if pattern.match?(entry.path)
        result << entry
      end

      if entry.dir? && pattern.could_match_children?(entry.path)
        # If it's possible that our children could match, descend in and add matches.
        exact_child_name = pattern.exact_child_name_under(entry.path)

        # If we've got an exact name, don't bother listing children; just grab the
        # child with the given name.
        if exact_child_name
          exact_child = entry.child(exact_child_name)
          if exact_child
            result = result.concat(list(exact_child, pattern))
          end

        # Otherwise, go through all children and find any matches
        else
          entry.children.each do |child|
            result = result.concat(list(child, pattern))
          end
        end
      end
      result
    end

    # Retrieve an exact path
    def self.get_path(entry, path)
      return entry if path.length == 0
      return get_path(entry.root, path) if path[0] == "/" && entry.root != entry
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

