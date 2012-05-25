require 'chef_fs/file_system/chef_server_root_dir'
require 'chef_fs/file_system/chef_repository_file_system_root_dir'
require 'chef_fs/file_pattern'
require 'chef_fs/path_utils'
require 'chef/config'

module ChefFS
  class Knife < Chef::Knife
    def self.common_options
      option :repo_mode,
        :long => '--repo-mode MODE',
        :default => "default",
        :description => "Specifies the local repository layout.  Values: default or full"
    end

    def base_path
      @base_path ||= begin
        relative_to_base = ChefFS::PathUtils::relative_to(File.expand_path(Dir.pwd), chef_repo)
        relative_to_base == '.' ? '/' : "/#{relative_to_base}"
      end
    end

    def chef_fs
      @chef_fs ||= ChefFS::FileSystem::ChefServerRootDir.new("remote", Chef::Config, config[:repo_mode])
    end

    def chef_repo
      @chef_repo ||= File.expand_path(File.join(Chef::Config.cookbook_path, ".."))
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
      @local_fs ||= ChefFS::FileSystem::ChefRepositoryFileSystemRootDir.new(chef_repo)
    end

    def pattern_args
      @pattern_args ||= pattern_args_from(name_args)
    end

    def pattern_args_from(args)
      args.map { |arg| ChefFS::FilePattern::relative_to(base_path, arg) }.to_a
    end

  end
end
