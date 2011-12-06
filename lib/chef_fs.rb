require 'chef_fs/file_system/chef_server_root_dir'
require 'chef/config'
require 'chef/rest'

class ChefFS
  def initialize(config = nil)
    @config = config || Chef::Config
  end

  attr_reader :config

  def list(pattern)
    root_directory.list(pattern)
  end

  private

  def root_directory
    @root_directory ||= ChefFS::FileSystem::ChefServerRootDir.new(config)
  end
end
