require 'bundler'
require 'rubygems'
require 'rake/gempackagetask'
require 'rspec/core/rake_task'
require 'rdoc/task'

Bundler::GemHelper.install_tasks

task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

gem_spec = eval(File.read("knife-essentials.gemspec"))

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "chef_fs #{gem_spec.version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

