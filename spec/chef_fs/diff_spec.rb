require 'support/file_system_support'
require 'chef_fs/diff'
require 'chef_fs/file_pattern'

describe ChefFS::Diff do
  include FileSystemSupport

	context 'diffable_leaves' do
		context 'both empty' do
		end
		context 'with differences' do
			let(:a) {
				memory_fs({
					:both_dirs => {
						:sub_both_dirs => { :subsub => '' },
						:sub_both_files => '',
						:sub_both_dirs_empty => {},
						:sub_a_only_dir => { :subsub => '' },
						:sub_a_only_file => '',
						:sub_dir_in_a_file_in_b => {},
						:sub_file_in_a_dir_in_b => ''
					},
					:both_files => '',
					:both_dirs_empty => {},
					:a_only_dir => { :subsub => '' },
					:a_only_file => '',
					:dir_in_a_file_in_b => {},
					:file_in_a_dir_in_b => ''
				})
			}
			let(:b) {
				memory_fs({
					:both_dirs => {
						:sub_both_dirs => { :subsub => '' },
						:sub_both_files => '',
						:sub_both_dirs_empty => {},
						:sub_b_only_dir => { :subsub => '' },
						:sub_b_only_file => '',
						:sub_dir_in_a_file_in_b => '',
						:sub_file_in_a_dir_in_b => {}
					},
					:both_files => '',
					:both_dirs_empty => {},
					:b_only_dir => { :subsub => '' },
					:b_only_file => '',
					:dir_in_a_file_in_b => '',
					:file_in_a_dir_in_b => {}
				})
			}
			it 'diffable_leaves' do
				diffable_leaves_should_yield_paths(a, b, nil,
          %w(
            /both_dirs/sub_both_dirs/subsub
            /both_dirs/sub_both_files
            /both_dirs/sub_both_dirs_empty
            /both_dirs/sub_a_only_dir
            /both_dirs/sub_a_only_file
            /both_dirs/sub_b_only_dir
            /both_dirs/sub_b_only_file
            /both_dirs/sub_dir_in_a_file_in_b
            /both_dirs/sub_file_in_a_dir_in_b
            /both_files
            /both_dirs_empty
            /a_only_dir
            /a_only_file
            /b_only_dir
            /b_only_file
            /dir_in_a_file_in_b
            /file_in_a_dir_in_b
          ))
			end
      it 'diffable_leaves_from_pattern(/**file*)' do
        diffable_leaves_from_pattern_should_yield_paths(pattern('/**file*'), a, b, nil,
          %w(
            /both_dirs/sub_both_files
            /both_dirs/sub_a_only_file
            /both_dirs/sub_b_only_file
            /both_dirs/sub_dir_in_a_file_in_b
            /both_dirs/sub_file_in_a_dir_in_b
            /both_files
            /a_only_file
            /b_only_file
            /dir_in_a_file_in_b
            /file_in_a_dir_in_b
          ))
      end
      it 'diffable_leaves_from_pattern(/*dir*)' do
        diffable_leaves_from_pattern_should_yield_paths(pattern('/*dir*'), a, b, nil,
          %w(
            /both_dirs/sub_both_dirs/subsub
            /both_dirs/sub_both_files
            /both_dirs/sub_both_dirs_empty
            /both_dirs/sub_a_only_dir
            /both_dirs/sub_a_only_file
            /both_dirs/sub_b_only_dir
            /both_dirs/sub_b_only_file
            /both_dirs/sub_dir_in_a_file_in_b
            /both_dirs/sub_file_in_a_dir_in_b
            /both_dirs_empty
            /a_only_dir
            /b_only_dir
            /dir_in_a_file_in_b
            /file_in_a_dir_in_b
          ))
      end
		end
		context 'when identical' do
		end
	end
end