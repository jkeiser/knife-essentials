require 'chef_fs/file_system/file_system_error'

module ChefFS
  module FileSystem
    class MustDeleteRecursivelyError < FileSystemError
      def initialize(cause = nil)
        super(cause)
      end
    end
  end
end
