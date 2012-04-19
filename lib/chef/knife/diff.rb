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
          ChefFS::Diff::common_leaves_from_pattern(pattern, chef_fs, local_fs, config[:recurse] ? nil : 1) do |chef_leaf, local_leaf|
            found_result = true
            ChefFS::Diff::diff_leaves(chef_leaf, local_leaf)
          end
          if !found_result && pattern.exact_path
            puts "#{pattern}: No such file or directory on remote or local"
          end
        end
      end
    end
  end
end

