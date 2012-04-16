require 'chef_fs/file_system/chef_server_root_dir'
require 'chef_fs/file_system/file_system_entry'
require 'chef_fs/file_pattern'
require 'chef/config'

module ChefFS
  class Knife < Chef::Knife
    def base_path
      @base_path ||= "/" + pwd_relative_to(chef_repo)
    end

    def chef_fs
      @chef_fs ||= ChefFS::FileSystem::ChefServerRootDir.new(Chef::Config)
    end

    def chef_repo
      @chef_repo ||= File.absolute_path(File.join(Chef::Config.cookbook_path, ".."))
    end

    def format_path(path)
      if path[0,base_path.length] == base_path
        if path == base_path
          return "."
        elsif path[base_path.length] == "/"
          return path[base_path.length + 1, path.length - base_path.length - 1]
        elsif base_path == "/" && path[0] == "/"
          return path[1, path.length - 1]
        end
      end
      path
    end

    def local_fs
      @local_fs ||= ChefFS::FileSystem::FileSystemEntry.new("", nil, chef_repo)
    end

    def pattern_args
      @pattern_args ||= pattern_args_from(name_args)
    end

    def pattern_args_from(args)
      args.map { |arg| ChefFS::FilePattern::relative_to(base_path, arg) }.to_a
    end

    def pwd_relative_to(dir)
      relative_to(File.absolute_path(Dir.pwd), dir)
    end

    def relative_to(path, to)
      raise "Paths #{path} and #{to} do not have a common base!" if path.length < to.length || path[0,to.length] != to
      path[to.length + 1, path.length - to.length - 1] || ""
    end
  end
end
