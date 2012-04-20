require 'chef_fs'
require 'chef_fs/path_utils'

module ChefFS
  #
  # Represents a glob pattern.  This class is designed so that it can
  # match arbitrary strings, and tell you about partial matches.
  #
  # Examples:
  # * <tt>a*z</tt>
  #   - Matches <tt>abcz</tt>
  #   - Does not match <tt>ab/cd/ez</tt>
  #   - Does not match <tt>xabcz</tt>
  # * <tt>a**z</tt>
  #   - Matches <tt>abcz</tt>
  #   - Matches <tt>ab/cd/ez</tt>
  #
  # Special characters supported:
  # * <tt>/</tt> (and <tt>\\</tt> on Windows) - directory separators
  # * <tt>\*</tt> - match zero or more characters (but not directory separators)
  # * <tt>\*\*</tt> - match zero or more characters, including directory separators
  # * <tt>?</tt> - match exactly one character (not a directory separator)
  # Only on Unix:
  # * <tt>[abc0-9]</tt> - match one of the included characters
  # * <tt>\\<character></tt> - escape character: match the given character
  #
  class FilePattern
    # Initialize a new FilePattern with the pattern string.
    def initialize(pattern)
      @pattern = pattern
    end

    # The pattern string.
    attr_reader :pattern

    # Reports whether this pattern could match children of <tt>path</tt>.
    # If the pattern doesn't match the path up to this point or
    # if it matches and doesn't allow further children, this will
    # return <tt>false</tt>.
    #
    #   abc/def.could_match_children?('abc') == true
    #   abc.could_match_children?('abc') == false
    #   abc/def.could_match_children?('x') == false
    #   a**z.could_match_children?('ab/cd') == true
    def could_match_children?(path)
      path_parts = ChefFS::PathUtils::split(path)
      # If the pattern is shorter than the path (or same size), children will be larger than the pattern, and will not match.
      return false if regexp_parts.length <= path_parts.length && !has_double_star
      # If the path doesn't match up to this point, children won't match either.
      return false if path_parts.zip(regexp_parts).any? { |part,regexp| !regexp.nil? && !regexp.match(part) }
      # Otherwise, it's possible we could match: the path matches to this point, and the pattern is longer than the path.
      # TODO There is one edge case where the double star comes after some characters like abc**def--we could check whether the next
      # bit of path starts with abc in that case.
      return true
    end

    # Returns the next child name in an exact path.
    #
    # If this pattern can only match one possible child of the
    # given <tt>path</tt>, this method returns its name.
    #
    #   abc/def.exact_child_name_under('abc') == 'def'
    #   abc/def/ghi.exact_child_name_under('abc') == 'def'
    #   abc/*/ghi.exact_child_name_under('abc') == nil
    #   abc/*/ghi.exact_child_name_under('abc/def') == 'ghi'
    #   abc/**/ghi.exact_child_name_under('abc/def') == nil
    # 
    # This method assumes <tt>could_match_children?(path)</tt> is <tt>true</tt>.
    def exact_child_name_under(path)
      dirs_in_path = ChefFS::PathUtils::split(path).length
      return nil if exact_parts.length <= dirs_in_path
      return exact_parts[dirs_in_path]
    end

    # If this pattern represents an exact path, returns the exact path.
    #
    #   abc/def.exact_path == 'abc/def'
    #   abc/*def.exact_path == 'abc/def'
    #   abc/x\\yz.exact_path == 'abc/xyz'
    def exact_path
      return nil if has_double_star || exact_parts.any? { |part| part.nil? }
      ChefFS::PathUtils::join(*exact_parts)
    end

    # Returns <tt>true+ if this pattern matches the path, <tt>false+ otherwise.
    #
    #   abc/*/def.match?('abc/foo/def') == true
    #   abc/*/def.match?('abc/foo') == false
    def match?(path)
      !!regexp.match(path)
    end

    # Returns the string pattern
    def to_s
      pattern
    end

    # Given a relative file pattern and a directory, makes a new file pattern
    # starting with the directory.
    #
    #   FilePattern.relative_to('/usr/local', 'bin/*grok') == FilePattern.new('/usr/local/bin/*grok')
    #
    # BUG: this does not support patterns starting with <tt>..</tt>
    def self.relative_to(dir, pattern)
      return FilePattern.new(pattern) if pattern =~ /^#{ChefFS::PathUtils::regexp_path_separator}/
      FilePattern.new(ChefFS::PathUtils::join(dir, pattern))
    end

  private

    def regexp
      calculate
      @regexp
    end

    def regexp_parts
      calculate
      @regexp_parts
    end

    def exact_parts
      calculate
      @exact_parts
    end

    def has_double_star
      calculate
      @has_double_star
    end

    def calculate
      if !@regexp
        full_regexp_parts = []
        @regexp_parts = []
        @exact_parts = []
        @has_double_star = false
        ChefFS::PathUtils::split(pattern).each do |part|
          regexp, exact, has_double_star = FilePattern::pattern_to_regexp(part)
          if has_double_star
            @has_double_star = true
          end
          if (exact == '' && full_regexp_parts.length > 0) || exact == '.'
            # Skip // and /./ (pretend it's not there)
          elsif exact == '..'
            # Back up when you see ..
            full_regexp_parts.pop
            if !@has_double_star
              @regexp_parts.pop
              @exact_parts.pop
            end
          else
            full_regexp_parts << regexp
            if !@has_double_star
              @regexp_parts << Regexp.new("^#{regexp}$")
              @exact_parts << exact
            end
          end
        end

        @regexp = Regexp.new("^#{full_regexp_parts.join(ChefFS::PathUtils::regexp_path_separator)}$")
      end
    end

    def self.regexp_special_characters
      if ChefFS::windows?
        @regexp_special_characters ||= /(\*\*|\*|\?|[\*\?\.\|\(\)\[\]\{\}\+\\\\\^\$])/
      else
        # Unix also supports character regexes and backslashes
        @regexp_special_characters ||= /(\\.|\[[^\]]+\]|\*\*|\*|\?|[\*\?\.\|\(\)\[\]\{\}\+\\\\\^\$])/
      end
      @regexp_special_characters
    end

    def self.pattern_to_regexp(pattern)
      regexp = ""
      exact = ""
      has_double_star = false
      pattern.split(regexp_special_characters).each_with_index do |part, index|
        # Odd indexes from the split are symbols.  Even are normal bits.
        if index % 2 == 0
          exact << part if !exact.nil?
          regexp << part
        else
          case part
          # **, * and ? happen on both platforms.
          when '**'
            exact = nil
            has_double_star = true
            regexp << '.*'
          when '*'
            exact = nil
            regexp << '[^\/]*'
          when '?'
            exact = nil
            regexp << '.'
          else
            if part[0] == '\\' && part.length == 2
              # backslash escapes are only supported on Unix, and are handled here by leaving the escape on (it means the same thing in a regex)
              exact << part[1] if !exact.nil?
              regexp << part
            elsif part[0] == '[' && part.length > 1
              # [...] happens only on Unix, and is handled here by *not* backslashing (it means the same thing in and out of regex)
              exact = nil
              regexp << part
            else
              exact += part if !exact.nil?
              regexp << "\\#{part}"
            end
          end
        end
      end
      [regexp, exact, has_double_star]
    end
  end
end