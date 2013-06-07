$:.unshift(File.dirname(__FILE__) + '/lib')
require 'chef_fs/version'

Gem::Specification.new do |s|
  s.name = "knife-essentials"
  s.version = ChefFS::VERSION
  s.license = 'Apache 2.0'
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc", "LICENSE"]
  s.summary = "Universal knife verbs that work with your Chef repository"
  s.description = s.summary
  s.author = "John Keiser"
  s.email = "jkeiser@opscode.com"
  s.homepage = "http://www.opscode.com"

  # We need a more recent version of mixlib-cli in order to support --no- options.
  # ... but, we can live with those options not working, if it means the plugin
  # can be included with apps that have restrictive Gemfile.locks.
  # s.add_dependency "mixlib-cli", ">= 1.2.2"
  s.add_dependency 'chef'
  s.add_development_dependency 'chef-zero', '>= 1.2'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'puma', '~> 1.6'

  s.require_path = 'lib'
  s.files = %w(LICENSE README.rdoc Rakefile) + Dir.glob("{lib,spec}/**/*")
end

