#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef_fs/file_system/base_fs_object'
require 'chef_fs/file_system/not_found_error'
require 'chef_fs/file_system/operation_failed_error'
require 'chef/role'
require 'chef/node'

module ChefFS
  module FileSystem
    class RestListEntry < BaseFSObject
      def initialize(name, parent, exists = nil)
        super(name, parent)
        @exists = exists
      end

      def data_handler
        parent.data_handler
      end

      def api_child_name
        if name.length < 5 || name[-5,5] != ".json"
          raise "Invalid name #{path}: must end in .json"
        end
        name[0,name.length-5]
      end

      def api_path
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
            raise ChefFS::FileSystem::NotFoundError.new(self, $!)
          else
            raise
          end
        end
      end

      def read
        # Minimize the value so the results don't look terrible
        Chef::JSONCompat.to_json_pretty(minimize_value(chef_hash))
      end

      def chef_hash
        JSON.parse(raw_request(api_path), :create_additions => false)
      rescue Net::HTTPServerException => e
        if $!.response.code == "404"
          raise ChefFS::FileSystem::NotFoundError.new(self, $!)
        else
          raise ChefFS::FileSystem::OperationFailedError.new(:read, self, e)
        end
      end

      def chef_object
        begin
          # REST will inflate the Chef object using json_class
          rest.get_rest(api_path)
        rescue Net::HTTPServerException => e
          if $!.response.code == "404"
            raise ChefFS::FileSystem::NotFoundError.new(self, $!)
          else
            raise ChefFS::FileSystem::OperationFailedError.new(:read, self, e)
          end
        end
      end

      def minimize_value(value)
        data_handler.minimize(data_handler.normalize(value, self), self)
      end

      def compare_to(other)
        # Grab the other value
        begin
          other_value_json = other.read
        rescue ChefFS::FileSystem::NotFoundError
          return [ nil, nil, :none ]
        end

        # Grab this value
        begin
          value = chef_object.to_hash
        rescue ChefFS::FileSystem::NotFoundError
          return [ false, :none, other_value_json ]
        end

        # Minimize (and normalize) both values for easy and beautiful diffs
        value = minimize_value(value)
        value_json = Chef::JSONCompat.to_json_pretty(value)
        begin
          #other_value = Chef::JSONCompat.from_json(other_value_json, :create_additions => false)
          other_value = JSON.parse(other_value_json, :create_additions => false)
        rescue JSON::ParserError => e
          Chef::Log.warn("Parse error reading #{other.path_for_printing} as JSON: #{e}")
          return [ nil, value_json, other_value_json ]
        end
        other_value = minimize_value(other_value)
        other_value_json = Chef::JSONCompat.to_json_pretty(other_value)

        [ value == other_value, value_json, other_value_json ]
      end

      def rest
        parent.rest
      end

      def write(file_contents)
        begin
          #object = Chef::JSONCompat.from_json(file_contents).to_hash
          object = JSON.parse(file_contents, :create_additions => false)
        rescue JSON::ParserError => e
          raise ChefFS::FileSystem::OperationFailedError.new(:write, self, e), "Parse error reading JSON: #{e}"
        end

        if data_handler
          object = data_handler.normalize(object, self)
        end

        base_name = name[0,name.length-5]
        if object['name'] != base_name
          raise ChefFS::FileSystem::OperationFailedError.new(:write, self), "Name in #{path_for_printing}/#{name} must be '#{base_name}' (is '#{object['name']}')"
        end

        begin
          rest.put_rest(api_path, object)
        rescue Net::HTTPServerException => e
          if e.response.code == "404"
            raise ChefFS::FileSystem::NotFoundError.new(self, e)
          else
            raise ChefFS::FileSystem::OperationFailedError.new(:write, self, e)
          end
        end
      end
    end
  end
end
