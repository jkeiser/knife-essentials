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

	class MemoryRoot < MemoryDir
		def initialize(pretty_name)
			super('', nil)
			@pretty_name = pretty_name
		end

		def path_for_printing
			@pretty_name
		end
	end

	def memory_fs(pretty_name, value)
		if !value.is_a?(Hash)
			raise "memory_fs() must take a Hash"
		end
		dir = MemoryRoot.new(pretty_name)
		value.each do |key, child|
			dir.add_child(memory_fs_value(child, key.to_s, dir))
		end
		dir
	end

	def memory_fs_value(value, name = '', parent = nil)
		if value.is_a?(Hash)
			dir = MemoryDir.new(name, parent)
			value.each do |key, child|
				dir.add_child(memory_fs_value(child, key.to_s, dir))
			end
			dir
		else
			MemoryFile.new(name, parent, value || "#{name}\n")
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

	def diffable_leaves_should_yield_paths(a_root, b_root, recurse_depth, expected_paths)
		result_paths = []
		ChefFS::Diff.diffable_leaves(a_root, b_root, recurse_depth) do |a,b|
			a.root.should == a_root
			b.root.should == b_root
			a.path.should == b.path
			result_paths << a.path
		end
		result_paths.should =~ expected_paths
	end

	def diffable_leaves_from_pattern_should_yield_paths(pattern, a_root, b_root, recurse_depth, expected_paths)
		result_paths = []
		ChefFS::Diff.diffable_leaves_from_pattern(pattern, a_root, b_root, recurse_depth) do |a,b|
			a.root.should == a_root
			b.root.should == b_root
			a.path.should == b.path
			result_paths << a.path
		end
		result_paths.should =~ expected_paths
	end

	def list_should_yield_paths(fs, pattern_str, *expected_paths)
		result_paths = []
		ChefFS::FileSystem.list(fs, pattern(pattern_str)) { |result| result_paths << result.path }
		result_paths.should =~ expected_paths
	end
end

