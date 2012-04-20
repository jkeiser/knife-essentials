require 'chef_fs/knife'
require 'chef_fs/diff'

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
          ChefFS::Diff::diffable_leaves_from_pattern(pattern, chef_fs, local_fs, config[:recurse] ? nil : 1) do |chef_leaf, local_leaf|
            found_result = true
            diff_leaves(chef_leaf, local_leaf)
          end
          if !found_result && pattern.exact_path
            puts "#{pattern}: No such file or directory on remote or local"
          end
        end
      end

      # Diff two known leaves (could be files or dirs)
      def diff_leaves(old_file, new_file)
        # If both are directories
        # If old is a directory and new is a file
        # If old is a directory and new does not exist
        if old_file.dir?
          if new_file.dir?
            puts "Common subdirectories: #{old_file.path}"
          elsif new_file.exists?
            puts "File #{new_file.path_for_printing} is a directory while file #{new_file.path_for_printing} is a regular file"
          else
            puts "Only in #{old_file.parent.path_for_printing}: #{old_file.name}"
          end

        # If new is a directory and old does not exist
        # If new is a directory and old is a file
        elsif new_file.dir?
          if old_file.exists?
            puts "File #{old_file.path_for_printing} is a regular file while file #{old_file.path_for_printing} is a directory"
          else
            puts "Only in #{new_file.parent.path_for_printing}: #{new_file.name}"
          end

        else
          # Neither is a directory, so they are diffable with file diff
          different, old_value, new_value = ChefFS::Diff::diff_files(old_file, new_file)
          if different
            old_path = old_file.path_for_printing
            new_path = new_file.path_for_printing
            puts "diff --knife #{old_path} #{new_path}"
            if !old_value
              puts "new file"
              old_path = "/dev/null"
              old_value = ''
            end
            if !new_value
              puts "deleted file"
              new_path = "/dev/null"
              new_value = ''
            end
            puts diff_text(old_path, new_path, old_value, new_value)
          end
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

    end
  end
end

