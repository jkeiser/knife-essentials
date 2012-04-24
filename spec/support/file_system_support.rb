require 'chef_fs/file_system'
require 'chef_fs/file_system/base_fs_dir'
require 'chef_fs/file_system/base_fs_object'

module FileSystemSupport
	class MemoryFile < ChefFS::FileSystem::BaseFSObject
		def initialize(name, parent, value)
			super(name, parent)
			@value = value
		end
		def read
			return @value
		end
	end

	class MemoryDir < ChefFS::FileSystem::BaseFSDir
		def initialize(name, parent)
			super(name, parent)
			@children = []
		end
		attr_reader :children
		def child(name)
			@children.select { |child| child.name == name }.first || ChefFS::FileSystem::NonexistentFSObject.new(name, self)
		end
		def add_child(child)
			@children.push(child)
		end
	end

	class ReturnPaths < RSpec::Matchers::BuiltIn::MatchArray
	  def initialize(expected)
	  	super(expected)
	  end
	  def matches?(results)
	  	super(results.map { |result| result.path })
	  end
	end

	def memory_fs(value, name = '', parent = nil)
		if value.is_a?(Hash)
			dir = MemoryDir.new(name, parent)
			value.each do |key, child|
				dir.add_child(memory_fs(child, key.to_s, dir))
			end
			dir
		else
			MemoryFile.new(name, parent, value)
		end
	end

	def pattern(p)
		ChefFS::FilePattern.new(p)
	end

	def return_paths(*expected)
		ReturnPaths.new(expected)
	end

	def no_blocking_calls_allowed
		[ MemoryFile, MemoryDir ].each do |c|
			[ :children, :exists?, :read ].each do |m|
				c.any_instance.stub(m).and_raise("#{m.to_s} should not be called")
			end
		end
	end

	def list_should_yield_paths(fs, pattern_str, *expected)
		results = []
		ChefFS::FileSystem.list(fs, pattern(pattern_str)) { |result| results << result }
		results.should return_paths(*expected)
	end
end

