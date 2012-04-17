require 'chef_fs/file_system/chef_server_root_dir'
require 'chef/config'
require 'chef/rest'

module ChefFS
  def self.windows?
    false
  end
end
