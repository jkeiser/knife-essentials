require 'chef_fs/file_system/chef_server_root_dir'

describe ChefFS::FileSystem::CookbooksDir do
  let(:root_dir) {
    ChefFS::FileSystem::ChefServerRootDir.new('remote',
    {
      :chef_server_url => 'url',
      :node_name => 'username',
      :client_key => 'key',
      :environment => 'env'
    })
  }
  let(:cookbooks_dir) { root_dir.child('cookbooks') }
  let(:should_list_cookbooks) do
    @rest.should_receive(:get_rest).with('cookbooks').once.and_return(
      {
        "achild" => "http://opscode.com/achild",
        "bchild" => "http://opscode.com/bchild"
      })
  end
  before(:each) do
    @rest = double("rest")
    Chef::REST.stub(:new).with('url','username','key') { @rest }
  end

  it 'has / as parent' do
    cookbooks_dir.parent.should == root_dir
  end
  it 'is a directory' do
    cookbooks_dir.dir?.should be_true
  end
  it 'exists' do
    cookbooks_dir.exists?.should be_true
  end
  it 'has path /cookbooks' do
    cookbooks_dir.path.should == '/cookbooks'
  end
  it 'has path_for_printing remote/cookbooks' do
    cookbooks_dir.path_for_printing.should == 'remote/cookbooks'
  end
  it 'has correct children' do
    should_list_cookbooks
    cookbooks_dir.children.map { |child| child.name }.should =~ %w(achild bchild)
  end
  it 'can have directories as children' do
    cookbooks_dir.can_have_child?('blah', true).should be_true
  end
  it 'cannot have files as children' do
    cookbooks_dir.can_have_child?('blah', false).should be_false
  end

  #
  # Cookbook dir (/cookbooks/<blah>)
  #
  shared_examples_for 'a cookbook' do
    let(:should_get_cookbook) do
      @rest.should_receive(:get_rest).with("cookbooks/#{cookbook_dir_name}/_latest").once.and_return(
        {
          "achild" => "http://opscode.com/achild",
          "bchild" => "http://opscode.com/bchild"
        })
    end
    it 'has cookbooks as parent' do
      cookbook_dir.parent == cookbooks_dir
    end
    it 'is a directory' do
      should_list_cookbooks
      cookbook_dir.dir?.should be_true
    end
    it 'exists' do
      should_list_cookbooks
      cookbook_dir.exists?.should be_true
    end
    it 'has path /cookbooks/<cookbook name>' do
      cookbook_dir.path.should == "/cookbooks/#{cookbook_dir_name}"
    end
    it 'has path_for_printing remote/cookbooks/<cookbook name>' do
      cookbook_dir.path_for_printing.should == "remote/cookbooks/#{cookbook_dir_name}"
    end
    it 'can have segment directories as children' do
      cookbook_dir.can_have_child?('attributes', true).should be_true
      cookbook_dir.can_have_child?('definitions', true).should be_true
      cookbook_dir.can_have_child?('recipes', true).should be_true
      cookbook_dir.can_have_child?('libraries', true).should be_true
      cookbook_dir.can_have_child?('templates', true).should be_true
      cookbook_dir.can_have_child?('files', true).should be_true
      cookbook_dir.can_have_child?('resources', true).should be_true
      cookbook_dir.can_have_child?('providers', true).should be_true
    end
    it 'cannot have arbitrary directories as children' do
      cookbook_dir.can_have_child?('blah', true).should be_false
      cookbook_dir.can_have_child?('root_files', true).should be_false
    end
    it 'can have files as children' do
      cookbook_dir.can_have_child?('blah', false).should be_true
      cookbook_dir.can_have_child?('root_files', false).should be_true
      cookbook_dir.can_have_child?('attributes', false).should be_true
      cookbook_dir.can_have_child?('definitions', false).should be_true
      cookbook_dir.can_have_child?('recipes', false).should be_true
      cookbook_dir.can_have_child?('libraries', false).should be_true
      cookbook_dir.can_have_child?('templates', false).should be_true
      cookbook_dir.can_have_child?('files', false).should be_true
      cookbook_dir.can_have_child?('resources', false).should be_true
      cookbook_dir.can_have_child?('providers', false).should be_true
    end
  end
  context 'achild from children' do
    let(:cookbook_dir_name) { 'achild' }
    let(:cookbook_dir) do
      should_list_cookbooks
      cookbooks_dir.children.select { |child| child.name == 'achild' }.first
    end
    it_behaves_like 'a cookbook'
  end
  context 'cookbooks_dir.child(achild)' do
    let(:cookbook_dir_name) { 'achild' }
    let(:cookbook_dir) { cookbooks_dir.child('achild') }
    it_behaves_like 'a cookbook'
  end
  context 'nonexistent child()' do
    let(:nonexistent_child) { cookbooks_dir.child('blah') }
    it 'has correct parent, name, path and path_for_printing' do
      nonexistent_child.parent.should == cookbooks_dir
      nonexistent_child.name.should == "blah"
      nonexistent_child.path.should == "/cookbooks/blah"
      nonexistent_child.path_for_printing.should == "remote/cookbooks/blah"
    end
    it 'does not exist' do
      should_list_cookbooks
      nonexistent_child.exists?.should be_false
    end
    it 'is a directory' do
      should_list_cookbooks
      nonexistent_child.dir?.should be_false
    end
    it 'read returns NotFoundException' do
      expect { nonexistent_child.read }.to raise_error(ChefFS::FileSystem::NotFoundException)
    end
  end

end