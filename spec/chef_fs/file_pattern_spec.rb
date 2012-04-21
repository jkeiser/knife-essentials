require 'chef_fs/file_pattern'

describe ChefFS::FilePattern do
	def p(str)
		ChefFS::FilePattern.new(str)
	end

	# Different kinds of patterns
	context 'with empty pattern ""' do
		let(:pattern) { ChefFS::FilePattern.new('') }
		it 'match?' do
			pattern.match?('').should be_true
			pattern.match?('/').should be_false
			pattern.match?('a').should be_false
			pattern.match?('a/b').should be_false
		end
		it 'exact_path' do
			pattern.exact_path.should == ''
		end
		it 'could_match_children?' do
			pattern.could_match_children?('').should be_false
			pattern.could_match_children?('a/b').should be_false
		end
	end

	context 'with root pattern "/"' do
		let(:pattern) { ChefFS::FilePattern.new('/') }
		it 'match?' do
			pattern.match?('/').should be_true
			pattern.match?('').should be_false
			pattern.match?('a').should be_false
			pattern.match?('/a').should be_false
		end
		it 'exact_path' do
			pattern.exact_path.should == '/'
		end
		it 'could_match_children?' do
			pattern.could_match_children?('').should be_false
			pattern.could_match_children?('/').should be_false
			pattern.could_match_children?('a').should be_false
			pattern.could_match_children?('a/b').should be_false
			pattern.could_match_children?('/a').should be_false
		end
	end

	context 'with simple pattern "abc"' do
		let(:pattern) { ChefFS::FilePattern.new('abc') }
		it 'match?' do
			pattern.match?('abc').should be_true
			pattern.match?('').should be_false
			pattern.match?('/').should be_false
			pattern.match?('a').should be_false
			pattern.match?('abcd').should be_false
			pattern.match?('/abc').should be_false
		end
		it 'exact_path' do
			pattern.exact_path.should == 'abc'
		end
		it 'could_match_children?' do
			pattern.could_match_children?('').should be_false
			pattern.could_match_children?('abc').should be_false
			pattern.could_match_children?('/abc').should be_false
		end
	end

	context 'with simple pattern "/abc"' do
		let(:pattern) { ChefFS::FilePattern.new('/abc') }
		it 'match?' do
			pattern.match?('/abc').should be_true
			pattern.match?('abc').should be_false
			pattern.match?('').should be_false
			pattern.match?('/').should be_false
			pattern.match?('a').should be_false
			pattern.match?('abcd').should be_false
		end
		it 'exact_path' do
			pattern.exact_path.should == '/abc'
		end
		it 'could_match_children?' do
			pattern.could_match_children?('/').should be_true
			pattern.could_match_children?('').should be_false
			pattern.could_match_children?('abc').should be_false
			pattern.could_match_children?('/abc').should be_false
		end
		it 'exact_child_name_under' do
			pattern.exact_child_name_under('/').should == 'abc'
			pattern.exact_child_name_under('').should == 'abc'
		end
	end

	context 'normalization tests' do
		it 'handles trailing slashes' do
			p('abc/').exact_path.should == 'abc'
			p('abc/').match?('abc').should be_true
		end
		it 'handles multiple slashes' do
			p('abc//def').exact_path.should == 'abc/def'
			p('abc//def').match?('abc/def').should be_true
			p('abc//').exact_path.should == 'abc'
			p('abc//').match?('abc').should be_true
		end
		it 'handles dot' do
			p('abc/./def').exact_path.should == 'abc/def'
			p('abc/./def').match?('abc/def').should be_true
		end
		it 'handles dotdot' do
			p('abc/../def').exact_path.should == 'def'
			p('abc/../def').match?('def').should be_true
			p('abc/def/../..').exact_path.should == ''
			p('abc/def/../..').match?('').should be_true
			p('/*/../def').exact_path.should == '/def'
			p('/*/../def').match?('/def').should be_true
			p('/*/*/../def').exact_path.should be_nil
			p('/*/*/../def').match?('/abc/def').should be_true
			p('/abc/def/../..').exact_path.should == '/'
			p('/abc/def/../..').match?('/').should be_true
		end
		it 'handles leading dotdot' do
			p('../abc/def').exact_path.should == 'abc/def'
			p('../abc/def').match?('abc/def').should be_true
			p('abc/../../def').exact_path.should == 'def'
			p('abc/../../def').match?('def').should be_true
			p('abc/**/../def').exact_path.should be_nil
			p('abc/**/../def').match?('abc/def').should be_true
			p('abc/**/../def').match?('abc/x/y/z/def').should be_true
			p('abc/**/../def').match?('def').should be_false
			p('/../abc/def').exact_path.should == '/abc/def'
			p('/../abc/def').match?('/abc/def').should be_true
		end
	end


	# match?
	#  - single element matches (empty, fixed, ?, *, characters, escapes)
	#  - nested matches
	#  - absolute matches
	#  - trailing slashes
	#  - **

	# exact_path
	#  - empty
	#  - single element and nested matches, with escapes
	#  - absolute and relative
	#  - ?, *, characters, **

	# could_match_children?
	# 
	#
	#
	#
	context 'with pattern "abc"' do
	end

	context 'with pattern "/abc"' do
	end

	context 'with pattern "abc/def/ghi"' do
	end

	context 'with pattern "/abc/def/ghi"' do
	end

	# Exercise the different methods to their maximum
end