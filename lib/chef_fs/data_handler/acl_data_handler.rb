require 'chef_fs/data_handler/data_handler_base'

module ChefFS
  module DataHandler
    class AclDataHandler < DataHandlerBase
      def normalize(node, entry)
        super(node, {})
      end
    end
  end
end
