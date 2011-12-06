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
        elsif base_path == "/" && path[0] == "/"
          return path[1, path.length - 1]
        end
      end
      path
    end

    def local_pattern(pattern)
      chef_repo + File.join(base_path, pattern.pattern)
    end

    def local_path(result)
      File.join(chef_repo, result.local_path)
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
      relative_to(File.absolute_path(Dir.pwd), dir)
    end

    def relative_to(path, to)
      raise "Paths #{path} and #{to} do not have a common base!" if path.length < to.length || path[0,to.length] != to
      path[to.length + 1, path.length - to.length - 1] || ""
    end
  end
end
