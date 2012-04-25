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
          ChefFS::CommandLine.diff(pattern, chef_fs, local_fs, config[:recurse] ? nil : 1) do |diff|
            puts diff
          end
        end
      end
    end
  end
end

