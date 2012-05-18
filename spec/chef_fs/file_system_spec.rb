require 'support/spec_helper'
require 'chef_fs/file_system'
require 'chef_fs/file_pattern'

describe ChefFS::FileSystem do
	include FileSystemSupport

	context 'with empty filesystem' do
		let(:fs) { memory_fs('', {}) }

		context 'list' do
			it '/' do
				list_should_yield_paths(fs, '/', '/')
			end
			it '/a' do
				list_should_yield_paths(fs, '/a', '/a')
			end
			it '/a/b' do
				list_should_yield_paths(fs, '/a/b')
			end
			it '/*' do
				list_should_yield_paths(fs, '/*', '/')
			end
		end

		context 'resolve_path' do
			it '/' do
				ChefFS::FileSystem.resolve_path(fs, '/').path.should == '/'
			end
			it 'nonexistent /a' do
				ChefFS::FileSystem.resolve_path(fs, '/a').path.should == '/a'
			end
			it 'nonexistent /a/b' do
				ChefFS::FileSystem.resolve_path(fs, '/a/b').path.should == '/a/b'
			end
		end
	end

	context 'with a populated filesystem' do
		let(:fs) {
			memory_fs('', {
				:a => {
					:aa => {
						:c => '',
						:zz => ''
					},
					:ab => {
						:c => '',
					}
				},
				:x => ''
			})
		}
		context 'list' do
			it '/**' do
				list_should_yield_paths(fs, '/**', '/', '/a', '/x', '/a/aa', '/a/aa/c', '/a/aa/zz', '/a/ab', '/a/ab/c')
			end
			it '/' do
				list_should_yield_paths(fs, '/', '/')
			end
			it '/*' do
				list_should_yield_paths(fs, '/*', '/', '/a', '/x')
			end
			it '/*/*' do
				list_should_yield_paths(fs, '/*/*', '/a/aa', '/a/ab')
			end
			it '/*/*/*' do
				list_should_yield_paths(fs, '/*/*/*', '/a/aa/c', '/a/aa/zz', '/a/ab/c')
			end
			it '/*/*/?' do
				list_should_yield_paths(fs, '/*/*/?', '/a/aa/c', '/a/ab/c')
			end
			it '/a/*/c' do
				list_should_yield_paths(fs, '/a/*/c', '/a/aa/c', '/a/ab/c')
			end
			it '/**b/c' do
				list_should_yield_paths(fs, '/**b/c', '/a/ab/c')
			end
			it '/a/ab/c' do
				no_blocking_calls_allowed
				list_should_yield_paths(fs, '/a/ab/c', '/a/ab/c')
			end
			it 'nonexistent /a/ab/blah' do
				no_blocking_calls_allowed
				list_should_yield_paths(fs, '/a/ab/blah', '/a/ab/blah')
			end
			it 'nonexistent /a/ab/blah/bjork' do
				no_blocking_calls_allowed
				list_should_yield_paths(fs, '/a/ab/blah/bjork')
			end
		end

		context 'resolve_path' do
			before(:each) do
				no_blocking_calls_allowed
			end
			it 'resolves /' do
				ChefFS::FileSystem.resolve_path(fs, '/').path.should == '/'
			end
			it 'resolves /x' do
				ChefFS::FileSystem.resolve_path(fs, '/x').path.should == '/x'
			end
			it 'resolves /a' do
				ChefFS::FileSystem.resolve_path(fs, '/a').path.should == '/a'
			end
			it 'resolves /a/aa' do
				ChefFS::FileSystem.resolve_path(fs, '/a/aa').path.should == '/a/aa'
			end
			it 'resolves /a/aa/zz' do
				ChefFS::FileSystem.resolve_path(fs, '/a/aa/zz').path.should == '/a/aa/zz'
			end
			it 'resolves nonexistent /y/x/w' do
				ChefFS::FileSystem.resolve_path(fs, '/y/x/w').path.should == '/y/x/w'
			end
		end
	end
end
