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

      COOKBOOK_SEGMENT_INFO = {
        :attributes => { :ruby_only => true },
        :definitions => { :ruby_only => true },
        :recipes => { :ruby_only => true },
        :libraries => { :ruby_only => true },
        :templates => { :recursive => true },
        :files => { :recursive => true },
        :resources => { :ruby_only => true, :recursive => true },
        :providers => { :ruby_only => true, :recursive => true },
        :root_files => { }
      }

      def add_child(child)
        @children << child
      end

      def api_path
        "#{parent.api_path}/#{name}/_latest"
      end

      def child(name)
        children.select { |child| child.name == name }.first || NonexistentFSObject.new(name, self)
      end

      def can_have_child?(name, is_dir)
        # A cookbook may have files in its root directory, and directories matching the known segment dirs
        if name != 'root_files' && Chef::CookbookVersion::COOKBOOK_SEGMENTS.any? { |segment| segment.to_s == name }
          return is_dir
        end
        !is_dir
      end

      def children
        if @children.nil?
          @children = []
          Chef::CookbookVersion::COOKBOOK_SEGMENTS.each do |segment|
            next unless manifest.has_key?(segment)
            segment_info = COOKBOOK_SEGMENT_INFO[segment]

            # Go through each file in the manifest for the segment, and
            # add cookbook subdirs and files for it.
            manifest[segment].each do |segment_file|
              parts = segment_file['path'].split('/')
              # Get or create the path to the file
              container = self
              parts[0,parts.length-1].each do |part|
                old_container = container
                container = old_container.children.select { |child| part == child.name }.first
                if !container
                  container = CookbookSubdir.new(part, old_container, segment_info[:ruby_only], segment_info[:recursive])
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

      def dir?
        exists?
      end

      def read
        # This will only be called if dir? is false, which means exists? is false.
        raise ChefFS::FileSystem::NotFoundException, path_for_printing
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
