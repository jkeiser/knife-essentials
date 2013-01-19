require 'chef/platform'

module ChefFS
  def self.windows?
    Chef::Platform.windows?
  end
end
