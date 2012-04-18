require 'chef_fs/file_system/base_fs_object'

module ChefFS
  module FileSystem
    class CookbookFile < BaseFSObject
      def initialize(name, parent, file)
        super(name, parent)
        @file = file
      end

      attr_reader :file

      def checksum
        file[:checksum]
      end

      def read
        old_sign_on_redirect = rest.sign_on_redirect
        rest.sign_on_redirect = false
        begin
          rest.get_rest(file['url'])
        ensure
          rest.sign_on_redirect = true
        end
      end

      def rest
        parent.rest
      end
    end
  end
end
