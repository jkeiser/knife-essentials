require 'pathname'
require 'tmpdir'
require 'tempfile'

class EssentialsRepoTranslator
  def initialize(options = {})
    @essentials_repo = options[:essentials_repo]
    @chef_repo = options[:chef_repo]
    @options = options
  end

  attr_reader :essentials_repo
  attr_reader :chef_repo
  attr_reader :options

  TRANSLATIONS = [
    {
      :essentials_path => 'lib/chef_fs/version.rb',
      :chef_path => nil
    },
    {
      :essentials_path => 'lib/chef_fs',
      :chef_path => 'lib/chef/chef_fs'
    },
    {
      :essentials_path => 'lib/chef_fs.rb',
      :chef_path => 'lib/chef/chef_fs.rb'
    },
    {
      :essentials_path => /^lib\/chef\/knife\/([^\/]+)_essentials.rb$/,
      :chef_path => 'lib/chef/knife/\1.rb',
    },
    {
      :essentials_path => 'spec/chef_fs',
      :chef_path => 'spec/unit/chef_fs'
    },
    {
      :essentials_path => 'spec/integration',
      :chef_path => 'spec/integration/knife'
    },
    {
      :essentials_path => 'spec/support/stickywicket.pem',
      :chef_path => nil
    },
    {
      :essentials_path => 'spec/support/file_system_support.rb',
      :chef_path => 'spec/support/shared/unit/file_system_support.rb'
    },
    {
      :essentials_path => 'spec/support/integration_helper.rb',
      :chef_path => 'spec/support/shared/integration/integration_helper.rb'
    },
    {
      :essentials_path => 'spec/support/knife_support.rb',
      :chef_path => 'spec/support/shared/integration/knife_support.rb'
    },
    {
      :essentials_path => 'spec/support/integration',
      :chef_path => 'spec/support/shared/integration'
    },
    {
      :essentials_path => 'spec/support/unit',
      :chef_path => 'spec/support/shared/unit'
    },
    {
      :essentials_path => 'spec/support/spec_helper.rb',
      :chef_path => nil
    },
    {
      :essentials_path => 'spec/spec_helper.rb',
      :chef_path => nil
    },
    {
      :essentials_path => 'tools',
      :chef_path => nil
    },
    {
      :essentials_path => 'pkg',
      :chef_path => nil
    },
    {
      :essentials_path => /^[^\/]+$/,
      :chef_path => nil
    }
  ]

  def translate_file_contents(essentials_relative)
    new_text = ''
    File.open("#{essentials_repo}/#{essentials_relative}") do |essentials_file|
      in_class = false
      skip_lines = nil
      essentials_file.each_line do |line|
        # We're being told to skip some lines ... make sure we're skipping what we think we're skipping
        if skip_lines
          expected = skip_lines.shift
          raise "Unexpected line #{line}" if line !~ /^\s*#{Regexp.escape(expected)}\s*$/
          skip_lines = nil if skip_lines.size == 0
          next
        end

        # Handle a block that exists for compatibility
        if line =~ /^(\s*)# Chef 11 changes this API(\s*$)/
          line = "#{$1}uploader.upload_cookbooks#{$2}"
          skip_lines = [
            'if uploader.respond_to?(:upload_cookbook)',
            'uploader.upload_cookbook',
            'else',
            'uploader.upload_cookbooks',
            'end'
          ]
        end

        # If we see "module ChefFS", add "class Chef" above it and indent
        if in_class
          if line =~ /^end\s*$/
            new_text << "  end\n"
            new_text << line
            in_class = false
            next
          end
          line = "  #{line}" unless line == "\n"
        else
          if line =~ /^module\s*ChefFS\s*$/
            new_text << "class Chef\n"
            new_text << "  module ChefFS\n"
            in_class = true
            next
          end
        end

        next if line =~ /remove_const/
        next if line =~ /^\s*ChefFS\s*=\s*::ChefFS\s*$/

        # Change requires and class prefixes
        line.sub!(/(require\s*')support\/spec_helper'/, '\1spec_helper\'')
        line.sub!(/(require\s*').*integration_helper'/, '\1support/shared/integration/integration_helper\'')
        line.sub!(/(require\s*').*knife_support'/, '\1support/shared/integration/knife_support\'')
        line.sub!(/(require\s*')chef_fs/, '\1chef/chef_fs')
        line.sub!(/(require\s*')chef\/knife\/(.+)_essentials'/, '\1chef/knife/\2\'')
        line.gsub!(/Chef::ChefFS/, 'ChefFS')
        line.gsub!(/::ChefFS/, '\1ChefFS')
        line.gsub!(/\bChefFS\b/, 'Chef::ChefFS')
        line.sub!('ACCEPT_ENCODING = "Accept-Encoding".freeze unless ACCEPT_ENCODING', 'ACCEPT_ENCODING = "Accept-Encoding".freeze')
        line.sub!('ENCODING_GZIP_DEFLATE = "gzip;q=1.0,deflate;q=0.6,identity;q=0.3".freeze unless ENCODING_GZIP_DEFLATE', 'ENCODING_GZIP_DEFLATE = "gzip;q=1.0,deflate;q=0.6,identity;q=0.3".freeze')

        new_text << line
      end
    end
    new_text
  end

  def translate_filename(filename)
    TRANSLATIONS.each do |translation|
      if translation[:essentials_path].is_a?(String)
        if filename == translation[:essentials_path] || filename.start_with?("#{translation[:essentials_path]}/")
          return nil if !translation[:chef_path]
          return filename.sub(/^#{translation[:essentials_path]}/, translation[:chef_path])
        end
      else
        if translation[:essentials_path].match(filename)
          return nil if !translation[:chef_path]
          return filename.sub(translation[:essentials_path], translation[:chef_path])
        end
      end
    end
    return :not_found
  end

  def translate_all
    @added_results = {}
    @modified_results = {}
    essentials_dir_to_chef('lib/chef_fs', 'lib/chef/chef_fs',
      :except => 'lib/chef_fs/version.rb',
      :purge => true)
    essentials_file_to_chef('lib/chef_fs.rb', 'lib/chef/chef_fs.rb')
    essentials_dir_to_chef('lib/chef/knife', 'lib/chef/knife',
      :filename_mapper => proc { |file| file.sub('_essentials.rb', '.rb') })
    essentials_dir_to_chef('spec/chef_fs', 'spec/unit/chef_fs')
    essentials_file_to_chef('spec/support/file_system_support.rb', 'spec/support/shared/unit/file_system_support.rb')
#    essentials_dir_to_chef('spec', 'spec', :except => 'spec/spec_helper.rb')
    [ @added_results, @modified_results ]
  end

  def essentials_dir_to_chef(essentials_dir, chef_dir, dir_options = {})
    if dir_options[:purge]
      Dir.glob("#{chef_repo}/#{chef_dir}/**/*") do |chef_path|
        relative_path = chef_path["#{chef_repo}/#{chef_dir}/".length..-1]
        essentials_path = "#{essentials_repo}/#{essentials_dir}/#{relative_path}"
        if !File.exist?(essentials_path)
          puts "D #{essentials_path} -> #{chef_path}"
          if !options[:dry_run]
          end
        end
      end
    end

    Dir.glob("#{essentials_repo}/#{essentials_dir}/**/*") do |essentials_path|
      unless File.directory?(essentials_path)
        relative_path = essentials_path["#{essentials_repo}/#{essentials_dir}/".length..-1]
        next if dir_options[:except] && dir_options[:except].include?(relative_path)
        essentials_relative = "#{essentials_dir}/#{relative_path}"
        relative_path = dir_options[:filename_mapper].call(relative_path) if dir_options[:filename_mapper]
        essentials_file_to_chef(essentials_relative, "#{chef_dir}/#{relative_path}")
      end
    end
  end

  def essentials_file_to_chef(essentials_relative, chef_relative)
    essentials_path = "#{essentials_repo}/#{essentials_relative}"
    chef_path = "#{chef_repo}/#{chef_relative}"

    new_text = translate_file_contents(essentials_path)

    if !File.exist?(chef_path)
      @added_results[essentials_relative] = chef_relative
      puts "A #{essentials_path} -> #{chef_path}"
    elsif new_text != File.read(chef_path)
      @modified_results[essentials_relative] = chef_relative
      puts "M #{essentials_path} -> #{chef_path}"
    else
      return
    end

    if !options[:dry_run]
      File.open(chef_path, 'w') do |chef_file|
        chef_file.write(new_text)
      end
    end
  end
end

class GitRepo
  def initialize(path)
    @path = path
  end

  attr_reader :path

  def git_dir
    "#{path}/.git"
  end

  def git(command)
    puts "git #{command} (#{path})"
    result = `git --git-dir=#{git_dir} --work-tree=#{path} #{command}`
    raise "git failed with exit status #{$?.exitstatus}!  Stdout/err:\n#{result}" if $?.exitstatus != 0
    result
  end

  def commits(start_commit, end_commit)
    commits = []
    current_commit = {}
    lines = Array(git("log -p --name-status #{start_commit}..#{end_commit}").lines)
    while lines.size > 0
      line = lines.shift
      if line =~ /^commit ([0-9a-f]+)$/
        commits << current_commit unless current_commit == {}
        current_commit = { :sha => $1, :fields => {}, :title => '', :files => [] }
      elsif line =~ /^(\w+):\s*(.+)/
        current_commit[:fields][$1] = $2
      elsif line == "\n"
      elsif line[0..3] == '    '
        current_commit[:title] << line[4..-1]
      elsif line =~ /^(M|A|D)\s+(.+)/
        current_commit[:files] << [ $1, $2 ]
      else
        raise "Unrecognized line in git log:\n#{line}"
      end
    end
    commits << current_commit unless current_commit == {}
    commits
  end
end

def error_ok(commit, file)
  return true if %w(
    8319c5ef9f3bf36e521f9e375f4ae8ab1eb5e504
    a30edcf035bc8bad6299f04b5b635850537273b8
    8038a91d99c0b49fe2eded353ab98ac7a145cca0
    9a683cb99d5c99b1e352c26a8a83027b666f3086
  ).include?(commit[:sha])
  return true if commit[:sha] == 'b66f16bf06538e2f2291bdb8778ecde9c96c8663' && file =~ /raw_essentials.rb/
  return false
end

chef_repo = GitRepo.new(Pathname.new(File.join(File.dirname(__FILE__), "..", "..", "chef")).cleanpath)
essentials_repo = GitRepo.new(Pathname.new(File.join(File.dirname(__FILE__), "..")).cleanpath)

dry_run = ARGV.length > 0 && ARGV.include?('--dry-run')
Dir.mktmpdir('essentials_repo') do |pristine_essentials_repo_path|
  system("git clone -l #{essentials_repo.path} #{pristine_essentials_repo_path}")
  pristine_essentials_repo = GitRepo.new(pristine_essentials_repo_path)

  puts "pristine #{pristine_essentials_repo.path}"
  puts "chef #{chef_repo.path}"
  translator = EssentialsRepoTranslator.new(
    :essentials_repo => pristine_essentials_repo.path,
    :chef_repo => chef_repo.path,
    :dry_run => dry_run
  )

  commits = pristine_essentials_repo.commits('chef_sync', 'master')
  commits.reverse.each do |commit|
    puts ""
    puts "Applying #{commit[:sha]} (#{commit[:title].chomp}) ..."
    pristine_essentials_repo.git("checkout -q #{commit[:sha]}")

    error = false
    modified_something = false
    commit[:files].each do |modification, file|
      relative_chef_file = translator.translate_filename(file)
      if relative_chef_file == :not_found
        error = true unless error_ok(commit, file)
        STDERR.puts "#{file} is untranslatable!  Fix your code, yo."
        next
      end
      if !relative_chef_file
        puts "#{file} has no equivalent in the Chef repo.  Skipping."
        next
      end

      chef_file = "#{chef_repo.path}/#{relative_chef_file}"
      puts "#{modification} #{file}"
      if modification == 'A'
        if File.exist?(chef_file)
          error = true unless error_ok(commit, file)
          STDERR.puts "Added file #{chef_file} already exists!"
        else
          Pathname.new(chef_file).dirname.mkpath
          contents = translator.translate_file_contents(file)
          File.open(chef_file, 'w') { |file| file.write(contents) }
          chef_repo.git("add #{relative_chef_file}")
          modified_something = true
        end

      elsif modification == 'M'
        contents = translator.translate_file_contents(file)
        if !File.exist?(chef_file)
          error = true unless error_ok(commit, file)
          STDERR.puts "Modified file #{chef_file} already exists!"
        elsif IO.read(chef_file) == contents
          error = true unless error_ok(commit, file)
          STDERR.puts "Modified file #{chef_file} not actually modified!"
        else
          File.open(chef_file, 'w') { |file| file.write(contents) }
          chef_repo.git("add #{relative_chef_file}")
          modified_something = true
        end

      elsif modification == 'D'
        if !File.exist?(chef_file)
          error = true unless error_ok(commit, file)
          STDERR.puts "Removed file #{chef_file} does not exist!"
        else
          chef_repo.git("rm #{relative_chef_file}")
          modified_something = true
        end
      end
    end

    if error
      puts "Errors.  Exiting."
      exit(1)
    end

    if !modified_something
      puts "No files in commit.  Skipping ..."
    else
      Tempfile.open('commit_message') do |file|
        file.write(commit[:title])
        file.close
        chef_repo.git("commit --author \"#{commit[:fields]['Author']}\" --date \"#{commit[:fields]['Date']}\" -F #{file.path}")
      end
    end
  end

end

puts ""
puts "That's all, folks!"
