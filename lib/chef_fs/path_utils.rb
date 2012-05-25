require 'chef_fs'

module ChefFS
  class PathUtils

    # If you are in 'source', this is what you would have to type to reach 'dest'
    # relative_to('/a/b/c/d/e', '/a/b/x/y') == '../../c/d/e'
    # relative_to('/a/b', '/a/b') == ''
    def self.relative_to(dest, source)
      # Skip past the common parts
      source_parts = ChefFS::PathUtils.split(source)
      dest_parts = ChefFS::PathUtils.split(dest)
      i = 0
      until i >= source_parts.length || i >= dest_parts.length || source_parts[i] != source_parts[i]
        i+=1
      end
      # dot-dot up from 'source' to the common ancestor, then
      # descend to 'dest' from the common ancestor
      result = ChefFS::PathUtils.join(*(['..']*(source_parts.length-i) + dest_parts[i,dest.length-i]))
      result == '' ? '.' : result
    end

    def self.join(*parts)
      return "" if parts.length == 0
      # Determine if it started with a slash
      absolute = parts[0].length == 0 || parts[0].length > 0 && parts[0] =~ /^#{regexp_path_separator}/
      # Remove leading and trailing slashes from each part so that the join will work (and the slash at the end will go away)
      parts = parts.map { |part| part.gsub(/^\/|\/$/, "") }
      # Don't join empty bits
      result = parts.select { |part| part != "" }.join("/")
      # Put the / back on
      absolute ? "/#{result}" : result
    end

    def self.split(path)
      path.split(Regexp.new(regexp_path_separator))
    end

    def self.regexp_path_separator
      ChefFS::windows? ? '[/\\]' : '/'
    end

  end
end
