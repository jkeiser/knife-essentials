require 'chef_fs/data_handler/data_handler_base'

module ChefFS
  module DataHandler
    class UserDataHandler < DataHandlerBase
      def self.normalize(user, name)
        super(user, {
          'name' => name,
          'admin' => false
        })
      end

      # There is no chef_class for users, nor does to_ruby work.
    end
  end
end
