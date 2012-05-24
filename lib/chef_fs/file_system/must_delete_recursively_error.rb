module ChefFS
  module FileSystem
    class MustDeleteRecursivelyError < FileSystemError
      def initialize(cause = nil)
        super(cause)
      end
    end
  end
end
