require 'chef_fs/file_system/rest_list_dir'
require 'chef_fs/file_system/cookbook_dir'

module ChefFS
  module FileSystem
    class CookbooksDir < RestListDir
      def initialize(parent)
        super("cookbooks", parent)
      end

      def child(name)
        result = @children.select { |child| child.name == name }.first if @children
        result || CookbookDir.new(name, self)
      end

      def children
        @children ||= rest.get_rest(api_path).map { |key, value| CookbookDir.new(key, self, value) }
      end

      def create_child_from(other)
        upload_cookbook_from(other)
      end

      def upload_cookbook_from(other)
        other_cookbook_version = other.chef_object
        # TODO this only works on the file system.  And it can't be broken into
        # pieces.
        begin
          Chef::CookbookUploader.new(other_cookbook_version, other.parent.file_path).upload_cookbook
        rescue Net::HTTPServerException => e
          case e.response.code
          when "409"
            ui.error "Version #{other_cookbook_version.version} of cookbook #{other_cookbook_version.name} is frozen. Use --force to override."
            Chef::Log.debug(e)
            raise Exceptions::CookbookFrozen
          else
            raise
          end
        end
      end

      def can_have_child?(name, is_dir)
        is_dir
      end
    end
  end
end
