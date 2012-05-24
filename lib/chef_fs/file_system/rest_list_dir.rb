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
        result ||= can_have_child?(name, false) ?
                   _make_child_entry(name) : NonexistentFSObject.new(name, self)
      end

      def can_have_child?(name, is_dir)
        name =~ /\.json$/ && !is_dir
      end

      def children
        begin
          @children ||= rest.get_rest(api_path).keys.map do |key|
            _make_child_entry("#{key}.json", true)
          end
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
        _make_child_entry(name, true)
      end

      def environment
        parent.environment
      end

      def rest
        parent.rest
      end

      def _make_child_entry(name, exists = nil)
        RestListEntry.new(name, self, exists)
      end
    end
  end
end
