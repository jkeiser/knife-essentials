require 'chef_fs/file_system/rest_list_dir'
require 'chef_fs/file_system/cookbook_subdir'
require 'chef_fs/file_system/cookbook_file'
require 'chef/cookbook_version'

module ChefFS
  module FileSystem
    class CookbookDir < BaseFSDir
      def initialize(name, parent, versions = nil)
        super(name, parent)
        @versions = versions
      end

      attr_reader :versions

      def add_child(child)
        @children << child
      end

      def api_path
        "#{parent.api_path}/#{name}/_latest"
      end

      def child(name)
        children.select { |child| child.name == name }.first || NonexistentFSObject.new(name, self)
      end

      def children
        if @children.nil?
          @children = []
          Chef::CookbookVersion::COOKBOOK_SEGMENTS.each do |segment|
            next unless manifest.has_key?(segment)
            manifest[segment].each do |segment_file|
              parts = segment_file['path'].split('/')
              # Get or create the path to the file
              container = self
              parts[0,parts.length-1].each do |part|
                old_container = container
                container = old_container.children.select { |child| part == child.name }.first
                if !container
                  container = CookbookSubdir.new(part, old_container)
                  old_container.add_child(container)
                end
              end
              # Create the file itself
              container.add_child(CookbookFile.new(parts[parts.length-1], container, segment_file))
            end
          end
        end
        @children
      end

      def exists?
        if !@versions
          child = parent.children.select { |child| child.name == name }.first
          @versions = child.versions if child
        end
        !!@versions
      end

      def rest
        parent.rest
      end

      private

      def manifest
        begin
          @manifest ||= rest.get_rest(api_path).manifest
        rescue Net::HTTPServerException
          if $!.response.code == "404"
            raise ChefFS::FileSystem::NotFoundException, $!
          else
            raise
          end
        end
      end
    end
  end
end
