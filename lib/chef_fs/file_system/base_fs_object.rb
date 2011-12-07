require 'chef_fs/file_pattern'

class ChefFS
  module FileSystem
    class BaseFSObject
      def initialize(name, parent)
        @name = name
        @parent = parent
        if parent
          @path = FilePattern::join_path(parent.path, name)
        else
          @path = name
        end
      end

      attr_reader :name
      attr_reader :parent
      attr_reader :path

      def dir?
        false
      end

      def exists?
        true
      end

      # Retrieve an exact path
      def get(path)
        raise "get only works on the root of a tree" if self.path != ""

        result = self
        FilePattern::split_path(path).each_with_index do |part, index|
          if index == 0
            raise "Must be an absolute path" if part != ""
          else
            result = result.child(part)
          end
        end
        result
      end

      # Get a list of all things under (and including) this entry that match the given pattern
      def list(pattern)
        result = []

        # Include self in results if it matches
        if pattern.match?(path)
          result << self
        end

        if dir? && pattern.could_match_children?(path)
          # If it's possible that our children could match, descend in and add matches.
          exact_child_name = pattern.exact_child_name_under(path)
          if exact_child_name
            # If we've got an exact name, short-circuit the network by asking for a child with the given name.
            exact_child = child(exact_child_name)
            if exact_child
              result = result.concat(exact_child.list(pattern))
            end
          else
            # Otherwise, go through all children and find any matches
            children.each do |child|
              result = result.concat(child.list(pattern))
            end
          end
        end
        result
      end

      # Abstract: read, write, delete
    end
  end
end
