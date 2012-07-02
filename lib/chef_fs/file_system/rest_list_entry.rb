require 'chef_fs/file_system/base_fs_object'
require 'chef_fs/file_system/not_found_error'
require 'chef/role'
require 'chef/node'

module ChefFS
  module FileSystem
    class RestListEntry < BaseFSObject
      def initialize(name, parent, exists = nil)
        super(name, parent)
        @exists = exists
      end

      def api_path
        if name.length < 5 || name[-5,5] != ".json"
          raise "Invalid name #{path}: must end in .json"
        end
        api_child_name = name[0,name.length-5]
        "#{parent.api_path}/#{api_child_name}"
      end

      def environment
        parent.environment
      end

      def exists?
        if @exists.nil?
          begin
            @exists = parent.children.any? { |child| child.name == name }
          rescue ChefFS::FileSystem::NotFoundError
            @exists = false
          end
        end
        @exists
      end

      def delete(recurse)
        begin
          rest.delete_rest(api_path)
        rescue Net::HTTPServerException
          if $!.response.code == "404"
            raise ChefFS::FileSystem::NotFoundError.new($!), "#{path_for_printing} not found"
          else
            raise
          end
        end
      end

      def read
        Chef::JSONCompat.to_json_pretty(chef_object.to_hash)
      end

      def chef_object
        begin
          # REST will inflate the Chef object using json_class
          rest.get_rest(api_path)
        rescue Net::HTTPServerException
          if $!.response.code == "404"
            raise ChefFS::FileSystem::NotFoundError.new($!), "#{path_for_printing} not found"
          else
            raise
          end
        end
      end

      def compare_to(other)
        begin
          other_value = other.read
        rescue ChefFS::FileSystem::NotFoundError
          return [ nil, nil, :none ]
        end
        begin
          value = chef_object.to_hash
        rescue ChefFS::FileSystem::NotFoundError
          return [ false, :none, other_value ]
        end
        are_same = (value == Chef::JSONCompat.from_json(other_value, :create_additions => false))
        [ are_same, Chef::JSONCompat.to_json_pretty(value), other_value ]
      end

      def rest
        parent.rest
      end

      def write(file_contents)
        json = Chef::JSONCompat.from_json(file_contents).to_hash
        base_name = name[0,name.length-5]
        if json['name'] != base_name
          raise "Name in #{path_for_printing}/#{name} must be '#{base_name}' (is '#{json['name']}')"
        end
        begin
          rest.put_rest(api_path, json)
        rescue Net::HTTPServerException
          if $!.response.code == "404"
            raise ChefFS::FileSystem::NotFoundError.new($!), "#{path_for_printing} not found"
          else
            raise
          end
        end
      end
    end
  end
end
