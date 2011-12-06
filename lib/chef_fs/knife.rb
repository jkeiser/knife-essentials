require 'chef_fs'
require 'chef/config'

class ChefFS
  class Knife < Chef::Knife
    def chef_repo
      @chef_repo ||= File.absolute_path(File.join(Chef::Config.cookbook_path, ".."))
    end

    def pwd_relative_to(dir)
      pwd = File.absolute_path(Dir.pwd)
      pwd[dir.length + 1, pwd.length - dir.length - 1] || ""
    end

    def chef_fs
      @chef_fs ||= ChefFS.new
    end
  end
end
