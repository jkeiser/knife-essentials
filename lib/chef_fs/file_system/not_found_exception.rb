module ChefFS
  module FileSystem
    class NotFoundException < Exception
      def initialize(other_exception)
        super(other_exception.respond_to?(:message) ? other_exception.message : message)
        @exception = other_exception
      end

      attr_reader :exception
    end
  end
end
