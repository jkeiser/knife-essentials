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
			pattern.match?('a').should be_false
			pattern.match?('abcd').should be_false
			pattern.match?('/abc').should be_false
			pattern.match?('').should be_false
			pattern.match?('/').should be_false
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
			pattern.match?('a').should be_false
			pattern.match?('abcd').should be_false
			pattern.match?('').should be_false
			pattern.match?('/').should be_false
		end
		it 'exact_path' do
			pattern.exact_path.should == '/abc'
		end
		it 'could_match_children?' do
			pattern.could_match_children?('abc').should be_false
			pattern.could_match_children?('/abc').should be_false
			pattern.could_match_children?('/').should be_true
			pattern.could_match_children?('').should be_false
		end
		it 'exact_child_name_under' do
			pattern.exact_child_name_under('/').should == 'abc'
			pattern.exact_child_name_under('').should == 'abc'
		end
	end

	context 'normalization tests' do
		it 'handles trailing slashes', :focus => true do
			p('abc/').normalized_pattern.should == 'abc'
			p('abc/').exact_path.should == 'abc'
			p('abc/').match?('abc').should be_true
			p('//').normalized_pattern.should == '/'
			p('//').exact_path.should == '/'
			p('//').match?('/').should be_true
			p('/./').normalized_pattern.should == '/'
			p('/./').exact_path.should == '/'
			p('/./').match?('/').should be_true
		end
		it 'handles multiple slashes' do
			p('abc//def').normalized_pattern.should == 'abc/def'
			p('abc//def').exact_path.should == 'abc/def'
			p('abc//def').match?('abc/def').should be_true
			p('abc//').normalized_pattern.should == 'abc'
			p('abc//').exact_path.should == 'abc'
			p('abc//').match?('abc').should be_true
		end
		it 'handles dot' do
			p('abc/./def').normalized_pattern.should == 'abc/def'
			p('abc/./def').exact_path.should == 'abc/def'
			p('abc/./def').match?('abc/def').should be_true
			p('./abc/def').normalized_pattern.should == 'abc/def'
			p('./abc/def').exact_path.should == 'abc/def'
			p('./abc/def').match?('abc/def').should be_true
			p('/.').normalized_pattern.should == '/'
			p('/.').exact_path.should == '/'
			p('/.').match?('/').should be_true
		end
		it 'handles dot by itself', :pending => "decide what to do with dot by itself" do
			p('.').normalized_pattern.should == '.'
			p('.').exact_path.should == '.'
			p('.').match?('.').should be_true
			p('./').normalized_pattern.should == '.'
			p('./').exact_path.should == '.'
			p('./').match?('.').should be_true
		end
		it 'handles dotdot' do
			p('abc/../def').normalized_pattern.should == 'def'
			p('abc/../def').exact_path.should == 'def'
			p('abc/../def').match?('def').should be_true
			p('abc/def/../..').normalized_pattern.should == ''
			p('abc/def/../..').exact_path.should == ''
			p('abc/def/../..').match?('').should be_true
			p('/*/../def').normalized_pattern.should == '/def'
			p('/*/../def').exact_path.should == '/def'
			p('/*/../def').match?('/def').should be_true
			p('/*/*/../def').normalized_pattern.should == '/*/def'
			p('/*/*/../def').exact_path.should be_nil
			p('/*/*/../def').match?('/abc/def').should be_true
			p('/abc/def/../..').normalized_pattern.should == '/'
			p('/abc/def/../..').exact_path.should == '/'
			p('/abc/def/../..').match?('/').should be_true
			p('abc/../../def').normalized_pattern.should == '../def'
			p('abc/../../def').exact_path.should == '../def'
			p('abc/../../def').match?('../def').should be_true
		end
		it 'handles dotdot with double star' do
			p('abc**/def/../ghi').exact_path.should be_nil
			p('abc**/def/../ghi').match?('abc/ghi').should be_true
			p('abc**/def/../ghi').match?('abc/x/y/z/ghi').should be_true
			p('abc**/def/../ghi').match?('ghi').should be_false
		end
		it 'raises error on dotdot with overlapping double star' do
			lambda { ChefFS::FilePattern.new('abc/**/../def').exact_path }.should raise_error(ArgumentError)
			lambda { ChefFS::FilePattern.new('abc/**/abc/../../def').exact_path }.should raise_error(ArgumentError)
		end
		it 'handles leading dotdot' do
			p('../abc/def').exact_path.should == '../abc/def'
			p('../abc/def').match?('../abc/def').should be_true
			p('/../abc/def').exact_path.should == '/abc/def'
			p('/../abc/def').match?('/abc/def').should be_true
			p('..').exact_path.should == '..'
			p('..').match?('..').should be_true
			p('/..').exact_path.should == '/'
			p('/..').match?('/').should be_true
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