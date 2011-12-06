require 'chef_fs/file_system/base_fs_dir'
require 'chef_fs/file_system/rest_list_entry'

# TODO: take environment into account

class ChefFS
  module FileSystem
    class DataBagDir < RestListDir
      def initialize(name, parent, exists = nil)
        super(name, parent)
        @exists = nil
      end

      def exists?
        if @exists.nil?
          @exists = parent.children.any? { |child| child.name == name }
        end
        @exists
      end
    end
  end
end
