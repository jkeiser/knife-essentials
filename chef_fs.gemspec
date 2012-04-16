$:.unshift(File.dirname(__FILE__) + '/lib')
require 'chef_fs/version'

Gem::Specification.new do |s|
  s.name = "chef_fs"
  s.version = ChefFS::VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc", "LICENSE"]
  s.summary = "A library that treats the Chef server as if it were a filesystem"
  s.description = s.summary
  s.author = "John Keiser"
  s.email = "jkeiser@opscode.com"
  s.homepage = "http://www.opscode.com"
  
  # Uncomment this to add a dependency
  #s.add_dependency "mixlib-log"
  
  s.require_path = 'lib'
  s.files = %w(LICENSE README.rdoc Rakefile) + Dir.glob("{lib,spec}/**/*")
end

