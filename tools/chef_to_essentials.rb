def chef_repo_to_essentials(chef_dir, essentials_dir)
  # lib/chef/chef_fs -> lib/chef_fs
  Dir.glob("#{chef_dir}/lib/chef/chef_fs/**/*") do |path|
    unless File.directory?(path)
      relative_path = path["#{chef_dir}/lib/chef/chef_fs/".length..-1]
      chef_file_to_essentials(path, "#{essentials_dir}/lib/chef_fs/#{relative_path}")
    end
  end
  # lib/chef/chef_fs.rb -> lib/chef_fs.rb
  chef_file_to_essentials("#{chef_dir}/lib/chef/chef_fs.rb", "#{essentials_dir}/lib/chef_fs.rb")
  # spec/unit/chef_fs -> spec/chef_fs
  Dir.glob("#{chef_dir}/spec/unit/chef_fs/**/*") do |path|
    unless File.directory?(path)
      relative_path = path["#{chef_dir}/spec/unit/chef_fs/".length..-1]
      chef_file_to_essentials(path, "#{essentials_dir}/spec/chef_fs/#{relative_path}")
    end
  end
  # lib/chef/knife/[delete|deps|diff|download|edit|list|raw|serve|show|upload|xargs].rb -> lib/chef/knife/*_essentials.rb
  %w(delete diff download list raw show upload).each do |knife_command|
    chef_file_to_essentials("#{chef_dir}/lib/chef/knife/#{knife_command}.rb", "#{essentials_dir}/lib/chef/knife/#{knife_command}_essentials.rb", true)
  end
  # spec/support/shared/unit/file_system_support.rb -> spec/support/file_system_support.rb
  chef_file_to_essentials("#{chef_dir}/spec/support/shared/unit/file_system_support.rb",
                          "#{essentials_dir}/spec/support/file_system_support.rb")
end

def chef_file_to_essentials(chef_path, essentials_path, is_knife_command=false)
  puts "#{chef_path} -> #{essentials_path}"
  File.open(chef_path) do |chef_file|
    File.open(essentials_path, "w") do |essentials_file|
      in_class = false
      chef_file.readlines.each do |line|
        unless is_knife_command
          # Remove and unindent from class Chef ... end
          if in_class
            if line =~ /^end\s*/
              in_class = false
              next
            end
            line = line[2..-1] if line[0..1] == '  '
          elsif line =~ /^class\s*Chef\s*$/
            in_class = true
            next
          end
        end

        next if line =~ /require 'support\/shared\/unit\/file_system_support'/

        # Change requires and class prefixes
        line.sub!(/(require\s*')spec_helper'/, '\1support/spec_helper\'')
        line.sub!(/(require\s*')chef\/chef_fs/, '\1chef_fs')
        line.gsub!(/\bChef::ChefFS\b/, 'ChefFS')
        line.sub!('ACCEPT_ENCODING = "Accept-Encoding".freeze', 'ACCEPT_ENCODING = "Accept-Encoding".freeze unless ACCEPT_ENCODING')
        line.sub!('ENCODING_GZIP_DEFLATE = "gzip;q=1.0,deflate;q=0.6,identity;q=0.3".freeze', 'ENCODING_GZIP_DEFLATE = "gzip;q=1.0,deflate;q=0.6,identity;q=0.3".freeze unless ENCODING_GZIP_DEFLATE')

        essentials_file.write(line)
      end
    end
  end
end

require 'tmpdir'

chef_dir = File.join(File.dirname(__FILE__), "..", "..", "chef")
essentials_dir = File.join(File.dirname(__FILE__), "..")
chef_repo_to_essentials(chef_dir, essentials_dir)
#Dir.mktmpdir do |essentials_tmp|
#  chef_repo_to_essentials(chef_dir, essentials_tmp)
#end
