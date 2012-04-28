module ChefFS
  module FileSystem
    class NotFoundError < StandardError
      def initialize(cause = nil)
        @cause = cause
      end

      attr_reader :cause
    end
  end
end
