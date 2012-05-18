require 'chef_fs/file_system'
require 'chef/json_compat'
require 'tempfile'
require 'fileutils'
require 'digest/md5'
require 'set'

module ChefFS
  class Diff
    def self.calc_checksum(value)
      return nil if value == nil
      Digest::MD5.hexdigest(value)
    end

    def self.diff_files_quick(old_file, new_file)
      # TODO change this so that it:
      # a. Asks old_file / new_file to diff each other
      # b. Add checksum to local fs for quick diff
      #
      # Short-circuit expensive comparison (could be an extra network
      # request) if a pre-calculated checksum is there
      #
      if new_file.respond_to?(:checksum)
        new_checksum = new_file.checksum
      end
      if old_file.respond_to?(:checksum)
        old_checksum = old_file.checksum
      end

      old_value = :not_retrieved
      new_value = :not_retrieved

      if old_checksum || new_checksum
        if !old_checksum
          old_value = read_file_value(old_file)
          if old_value
            old_checksum = calc_checksum(old_value)
          end
        end
        if !new_checksum
          new_value = read_file_value(new_file)
          if new_value
            new_checksum = calc_checksum(new_value)
          end
        end

        # If the checksums are the same, the files are the same.
        # (If they are different, it's possible that a content-aware
        # JSON diff will still think they are the same.)
        return [ true, old_value, new_value ]
      end

      return [ nil, old_value, new_value ]
    end

    def self.diff_files(old_file, new_file)
      different, old_value, new_value = diff_files_quick(old_file, new_file)
      if different != nil
        return different
      end

      #
      # Grab the values if we don't have them already from calculating checksum
      #
      old_value = read_file_value(old_file) if old_value == :not_retrieved
      new_value = read_file_value(new_file) if new_value == :not_retrieved

      return false if old_value == new_value
      return false if old_value && new_value && context_aware_diff(old_file, new_file, old_value, new_value) == false
      return [ true, old_value, new_value ]
    end

    def self.context_aware_diff(old_file, new_file, old_value, new_value)
      if old_file.content_type == :json || new_file.content_type == :json
        begin
          new_value = Chef::JSONCompat.from_json(new_value).to_hash
          old_value = Chef::JSONCompat.from_json(old_value).to_hash
          return old_value != new_value
        rescue JSON::ParserError
        end
      end
      return nil
    end

    private

    def self.read_file_value(file)
      begin
        return file.read
      rescue ChefFS::FileSystem::NotFoundError
        return nil
      end
    end
  end
end

