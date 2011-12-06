require 'chef_fs/file_system/base_fs_dir'
require 'chef_fs/file_system/rest_list_dir'

class ChefFS
  module FileSystem
    class RootDir < BaseFSDir
      def initialize(rest)
        super("", nil)
        @rest = rest
      end

      attr_reader :rest

      def children
        @children ||= [
          RestListDir.new("clients", self),
          RestListDir.new("cookbooks", self),
          RestListDir.new("data_bags", self, "data"),
          RestListDir.new("environments", self),
          RestListDir.new("nodes", self),
          RestListDir.new("roles", self),
  #        RestListDir.new("sandboxes", self),
  #        RestListDir.new("users", self)
        ]
      end
    end
  end
end
