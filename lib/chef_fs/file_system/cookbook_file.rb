require 'chef_fs/file_system/base_fs_object'
require 'digest/md5'

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
          rest.get_rest(file[:url])
        ensure
          rest.sign_on_redirect = old_sign_on_redirect
        end
      end

      def rest
        parent.rest
      end

      def compare_to(other)
        other_value = nil
        if other.respond_to?(:checksum)
          other_checksum = other.checksum
        else
          begin
            other_value = other.read
          rescue ChefFS::FileSystem::NotFoundError
            return [ false, nil, :none ]
          end
          other_checksum = calc_checksum(other_value)
        end
        [ checksum == other_checksum, nil, other_value ]
      end

      private

      def calc_checksum(value)
        begin
          Digest::MD5.hexdigest(value)
        rescue ChefFS::FileSystem::NotFoundError
          nil
        end
      end
    end
  end
end
