require 'chef_fs/file_system/base_fs_dir'
require 'chef_fs/file_system/rest_list_entry'
require 'chef_fs/file_system/not_found_error'

module ChefFS
  module FileSystem
    class RestListDir < BaseFSDir
      def initialize(name, parent, api_path = nil)
        super(name, parent)
        @api_path = api_path || (parent.api_path == "" ? name : "#{parent.api_path}/#{name}")
      end

      attr_reader :api_path

      def child(name)
        result = @children.select { |child| child.name == name }.first if @children
        result ||= can_have_child?(name, false) ? RestListEntry.new(name, self) : NonexistentFSObject.new(name, self)
      end

      def can_have_child?(name, is_dir)
        name =~ /\.json$/ && !is_dir
      end

      def children
        begin
          @children ||= rest.get_rest(api_path).keys.map { |key| RestListEntry.new("#{key}.json", self, true) }
        rescue Net::HTTPServerException
          if $!.response.code == "404"
            raise ChefFS::FileSystem::NotFoundError.new($!), "#{path_for_printing} not found"
          else
            raise
          end
        end
      end

      def create_child(name, file_contents)
        json = Chef::JSONCompat.from_json(file_contents).to_hash
        base_name = name[0,name.length-5]
        if json.include?('name') && json['name'] != base_name
          raise "Name in #{path_for_printing}/#{name} must be '#{base_name}' (is '#{json['name']}')"
        elsif json.include?('id') && json['id'] != base_name
          raise "Name in #{path_for_printing}/#{name} must be '#{base_name}' (is '#{json['id']}')"
        end
        rest.post_rest(api_path, json)
        RestListEntry.new(name, self, true)
      end

      def environment
        parent.environment
      end

      def rest
        parent.rest
      end
    end
  end
end
