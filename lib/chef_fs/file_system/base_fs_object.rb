require 'chef_fs/file_pattern'

module ChefFS
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

      def root
        parent ? parent.root : self
      end

      def actual_path
        if parent
          FilePattern::join_path(parent.actual_path, name)
        else
          name
        end
      end

      def dir?
        false
      end

      def exists?
        true
      end

      # Retrieve an exact path
      def get(path)
        return self if path.length == 0
        return parent.get(path) if path[0] == "/" && self.path != ""
        if path[0] == "/"
          path = path[1,path.length-1]
        end

        result = self
        FilePattern::split_path(path).each do |part|
          result = result.child(part)
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

      def content_type
        :text
      end

      # Abstract: read, write, delete
    end
  end
end
