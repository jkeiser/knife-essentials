require 'support/file_system_support'
require 'chef_fs/diff'
require 'chef_fs/file_pattern'
require 'chef_fs/command_line'

describe ChefFS::Diff do
  include FileSystemSupport

	context 'with two filesystems with all types of difference' do
		let(:a) {
			memory_fs('a', {
				:both_dirs => {
					:sub_both_dirs => { :subsub => nil },
          :sub_both_files => nil,
          :sub_both_files_different => "a\n",
					:sub_both_dirs_empty => {},
					:sub_a_only_dir => { :subsub => nil },
					:sub_a_only_file => nil,
					:sub_dir_in_a_file_in_b => {},
					:sub_file_in_a_dir_in_b => nil
				},
				:both_files => nil,
        :both_files_different => "a\n",
				:both_dirs_empty => {},
				:a_only_dir => { :subsub => nil },
				:a_only_file => nil,
				:dir_in_a_file_in_b => {},
				:file_in_a_dir_in_b => nil
			})
		}
		let(:b) {
			memory_fs('b', {
				:both_dirs => {
					:sub_both_dirs => { :subsub => nil },
					:sub_both_files => nil,
          :sub_both_files_different => "b\n",
					:sub_both_dirs_empty => {},
					:sub_b_only_dir => { :subsub => nil },
					:sub_b_only_file => nil,
					:sub_dir_in_a_file_in_b => nil,
					:sub_file_in_a_dir_in_b => {}
				},
				:both_files => nil,
        :both_files_different => "b\n",
				:both_dirs_empty => {},
				:b_only_dir => { :subsub => nil },
				:b_only_file => nil,
				:dir_in_a_file_in_b => nil,
				:file_in_a_dir_in_b => {}
			})
		}
		it 'diffable_leaves' do
			diffable_leaves_should_yield_paths(a, b, nil,
        %w(
          /both_dirs/sub_both_dirs/subsub
          /both_dirs/sub_both_files
          /both_dirs/sub_both_files_different
          /both_dirs/sub_both_dirs_empty
          /both_dirs/sub_a_only_dir
          /both_dirs/sub_a_only_file
          /both_dirs/sub_b_only_dir
          /both_dirs/sub_b_only_file
          /both_dirs/sub_dir_in_a_file_in_b
          /both_dirs/sub_file_in_a_dir_in_b
          /both_files
          /both_files_different
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
          /both_dirs/sub_both_files_different
          /both_dirs/sub_a_only_file
          /both_dirs/sub_b_only_file
          /both_dirs/sub_dir_in_a_file_in_b
          /both_dirs/sub_file_in_a_dir_in_b
          /both_files
          /both_files_different
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
          /both_dirs/sub_both_files_different
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
    it 'ChefFS::CommandLine.diff(/)' do
      results = []
      ChefFS::CommandLine.diff(pattern('/'), a, b, nil) do |diff|
        results << diff.gsub(/\s+\d\d\d\d-\d\d-\d\d\s\d?\d:\d\d:\d\d\.\d{9} -\d\d\d\d/, ' DATE')
      end
      results.should =~ [
        'diff --knife a/both_dirs/sub_both_files_different b/both_dirs/sub_both_files_different
--- a/both_dirs/sub_both_files_different DATE
+++ b/both_dirs/sub_both_files_different DATE
@@ -1 +1 @@
-a
+b
','Common subdirectories: /both_dirs/sub_both_dirs_empty
','Only in a/both_dirs: sub_a_only_dir
','diff --knife a/both_dirs/sub_a_only_file b/both_dirs/sub_a_only_file
deleted file
--- a/both_dirs/sub_a_only_file DATE
+++ /dev/null DATE
@@ -1 +0,0 @@
-sub_a_only_file
','File b/both_dirs/sub_dir_in_a_file_in_b is a directory while file b/both_dirs/sub_dir_in_a_file_in_b is a regular file
','File a/both_dirs/sub_file_in_a_dir_in_b is a regular file while file a/both_dirs/sub_file_in_a_dir_in_b is a directory
','Only in b/both_dirs: sub_b_only_dir
','diff --knife a/both_dirs/sub_b_only_file b/both_dirs/sub_b_only_file
new file
--- /dev/null DATE
+++ b/both_dirs/sub_b_only_file DATE
@@ -0,0 +1 @@
+sub_b_only_file
','diff --knife a/both_files_different b/both_files_different
--- a/both_files_different DATE
+++ b/both_files_different DATE
@@ -1 +1 @@
-a
+b
','Common subdirectories: /both_dirs_empty
','Only in a: a_only_dir
','diff --knife a/a_only_file b/a_only_file
deleted file
--- a/a_only_file DATE
+++ /dev/null DATE
@@ -1 +0,0 @@
-a_only_file
','File b/dir_in_a_file_in_b is a directory while file b/dir_in_a_file_in_b is a regular file
','File a/file_in_a_dir_in_b is a regular file while file a/file_in_a_dir_in_b is a directory
','Only in b: b_only_dir
','diff --knife a/b_only_file b/b_only_file
new file
--- /dev/null DATE
+++ b/b_only_file DATE
@@ -0,0 +1 @@
+b_only_file
' ]
    end
    it 'ChefFS::CommandLine.diff(/both_dirs)' do
      results = []
      ChefFS::CommandLine.diff(pattern('/both_dirs'), a, b, nil) do |diff|
        results << diff.gsub(/\s+\d\d\d\d-\d\d-\d\d\s\d?\d:\d\d:\d\d\.\d{9} -\d\d\d\d/, ' DATE')
      end
      results.should =~ [
        'diff --knife a/both_dirs/sub_both_files_different b/both_dirs/sub_both_files_different
--- a/both_dirs/sub_both_files_different DATE
+++ b/both_dirs/sub_both_files_different DATE
@@ -1 +1 @@
-a
+b
','Common subdirectories: /both_dirs/sub_both_dirs_empty
','Only in a/both_dirs: sub_a_only_dir
','diff --knife a/both_dirs/sub_a_only_file b/both_dirs/sub_a_only_file
deleted file
--- a/both_dirs/sub_a_only_file DATE
+++ /dev/null DATE
@@ -1 +0,0 @@
-sub_a_only_file
','File b/both_dirs/sub_dir_in_a_file_in_b is a directory while file b/both_dirs/sub_dir_in_a_file_in_b is a regular file
','File a/both_dirs/sub_file_in_a_dir_in_b is a regular file while file a/both_dirs/sub_file_in_a_dir_in_b is a directory
','Only in b/both_dirs: sub_b_only_dir
','diff --knife a/both_dirs/sub_b_only_file b/both_dirs/sub_b_only_file
new file
--- /dev/null DATE
+++ b/both_dirs/sub_b_only_file DATE
@@ -0,0 +1 @@
+sub_b_only_file
' ]
    end
    it 'ChefFS::CommandLine.diff(/) with depth 1' do
      results = []
      ChefFS::CommandLine.diff(pattern('/'), a, b, 1) do |diff|
        results << diff.gsub(/\s+\d\d\d\d-\d\d-\d\d\s\d?\d:\d\d:\d\d\.\d{9} -\d\d\d\d/, ' DATE')
      end
      results.should =~ [
'Common subdirectories: /both_dirs
','diff --knife a/both_files_different b/both_files_different
--- a/both_files_different DATE
+++ b/both_files_different DATE
@@ -1 +1 @@
-a
+b
','Common subdirectories: /both_dirs_empty
','Only in a: a_only_dir
','diff --knife a/a_only_file b/a_only_file
deleted file
--- a/a_only_file DATE
+++ /dev/null DATE
@@ -1 +0,0 @@
-a_only_file
','File b/dir_in_a_file_in_b is a directory while file b/dir_in_a_file_in_b is a regular file
','File a/file_in_a_dir_in_b is a regular file while file a/file_in_a_dir_in_b is a directory
','Only in b: b_only_dir
','diff --knife a/b_only_file b/b_only_file
new file
--- /dev/null DATE
+++ b/b_only_file DATE
@@ -0,0 +1 @@
+b_only_file
' ]
    end
    it 'ChefFS::CommandLine.diff(/*_*) with depth 0' do
      results = []
      ChefFS::CommandLine.diff(pattern('/*_*'), a, b, 0) do |diff|
        results << diff.gsub(/\s+\d\d\d\d-\d\d-\d\d\s\d?\d:\d\d:\d\d\.\d{9} -\d\d\d\d/, ' DATE')
      end
      results.should =~ [
'Common subdirectories: /both_dirs
','diff --knife a/both_files_different b/both_files_different
--- a/both_files_different DATE
+++ b/both_files_different DATE
@@ -1 +1 @@
-a
+b
','Common subdirectories: /both_dirs_empty
','Only in a: a_only_dir
','diff --knife a/a_only_file b/a_only_file
deleted file
--- a/a_only_file DATE
+++ /dev/null DATE
@@ -1 +0,0 @@
-a_only_file
','File b/dir_in_a_file_in_b is a directory while file b/dir_in_a_file_in_b is a regular file
','File a/file_in_a_dir_in_b is a regular file while file a/file_in_a_dir_in_b is a directory
','Only in b: b_only_dir
','diff --knife a/b_only_file b/b_only_file
new file
--- /dev/null DATE
+++ b/b_only_file DATE
@@ -0,0 +1 @@
+b_only_file
' ]
    end
  end
end