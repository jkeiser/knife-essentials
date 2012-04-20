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
        # If both files exist ...
        if old_file.exists? && new_file.exists?
          if old_file.dir?
            if new_file.dir?
              puts "Common subdirectories: #{old_file.path}"
            else
              puts "File #{new_file.path_for_printing} is a directory while file #{new_file.path_for_printing} is a regular file"
            end
          else
            if new_file.dir?
              puts "File #{old_file.path_for_printing} is a regular file while file #{old_file.path_for_printing} is a directory"
            else
              diff = ChefFS::Diff::diff_files(old_file, new_file)
              puts diff if diff
            end
          end

        # If only the old file exists ...
        elsif old_file.exists?
          if old_file.dir?
            puts "Only in #{old_file.parent.path_for_printing}: #{old_file.name}"
          else
            diff = ChefFS::Diff::diff_text(old_file.path_for_printing, '/dev/null', old_file.read, '')
            puts diff if diff
          end

        # If only the new file exists ...
        else
          if new_file.dir?
            puts "Only in #{new_file.parent.path_for_printing}: #{new_file.name}"
          else
            diff = ChefFS::Diff::diff_text('/dev/null', new_file.path_for_printing, '', new_file.read)
            puts diff if diff
          end
        end
      end

    end
  end
end

