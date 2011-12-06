require 'chef_fs'
require 'chef_fs/file_pattern'
require 'chef/config'

class ChefFS
  class Knife < Chef::Knife
    def base_path
      @base_path ||= "/" + pwd_relative_to(chef_repo)
    end

    def chef_fs
      @chef_fs ||= ChefFS.new
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
        end
      end
      path
    end

    def pattern_args
      @pattern_args ||= pattern_args_from(name_args)
    end

    def pattern_args_from(args)
      args.map do |arg|
        # Local file system globs can turn up ".json" extensions.  Strip them before we hit the server.
        arg = arg[0,arg.length-5] if arg =~ /\.json$/
        ChefFS::FilePattern::relative_to("/" + base_path, arg)
      end.to_a
    end

    def pwd_relative_to(dir)
      pwd = File.absolute_path(Dir.pwd)
      pwd[dir.length + 1, pwd.length - dir.length - 1] || ""
    end
  end
end
