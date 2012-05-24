module ChefFS
  module FileSystem
    class FileSystemError < StandardError
      def initialize(cause = nil)
        @cause = cause
      end

      attr_reader :cause
    end
  end
end
