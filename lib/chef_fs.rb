require 'chef_fs/file_system/root_dir'
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

  def rest
    Chef::REST.new(config[:chef_server_url])
  end

  private

  def root_directory
    @root_directory ||= ChefFS::FileSystem::RootDir.new(rest)
  end
end
