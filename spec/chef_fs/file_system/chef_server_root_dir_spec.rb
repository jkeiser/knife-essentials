require 'chef_fs/file_system/chef_server_root_dir'

describe ChefFS::FileSystem::ChefServerRootDir do
  let(:root_dir) {
    ChefFS::FileSystem::ChefServerRootDir.new('remote',
    {
      :chef_server_url => 'url',
      :node_name => 'username',
      :client_key => 'key',
      :environment => 'blah'
    })
  }
  before(:each) do
    @rest = double("rest")
    Chef::REST.stub(:new).with('url','username','key') { @rest }
  end
  context 'the root directory' do
    it 'has no parent' do
      root_dir.parent.should == nil
    end
    it 'is a directory' do
      root_dir.dir?.should be_true
    end
    it 'exists' do
      root_dir.exists?.should be_true
    end
    it 'has path /' do
      root_dir.path.should == '/'
    end
    it 'has path_for_printing remote/' do
      root_dir.path_for_printing.should == 'remote/'
    end
    it 'has correct children' do
      root_dir.children.map { |child| child.name }.should =~ %w(clients cookbooks data_bags environments nodes roles)
    end
    it 'can have children with the known names' do
      %w(clients cookbooks data_bags environments nodes roles).each { |child| root_dir.can_have_child?(child, true).should be_true }
    end
    it 'cannot have files as children' do
      %w(clients cookbooks data_bags environments nodes roles).each { |child| root_dir.can_have_child?(child, false).should be_false }
      root_dir.can_have_child?('blah', false).should be_false
    end
    it 'cannot have other child directories than the known names' do
      root_dir.can_have_child?('blah', true).should be_false
    end
    it 'child() responds to children' do
      %w(clients cookbooks data_bags environments nodes roles).each { |child| root_dir.child(child).exists?.should be_true }
    end
    it 'child() gives nonexistent other children' do
      root_dir.child('blah').exists?.should be_false
    end
  end

  context 'clients' do
    let(:clients) { root_dir.child('clients') }
    it 'parent is root' do
      clients.parent.should == root_dir
    end
    it 'is a directory' do
      clients.dir?.should be_true
    end
    it 'exists' do
      clients.exists?.should be_true
    end
    it 'has path /clients' do
      clients.path.should == '/clients'
    end
    it 'has path_for_printing remote/clients' do
      clients.path_for_printing.should == 'remote/clients'
    end
    it 'can have json files as children' do
      clients.can_have_child?('blah.json', false).should be_true
    end
    it 'cannot have non-json files as children' do
      clients.can_have_child?('blah', false).should be_false
    end
    it 'cannot have directories as children' do
      clients.can_have_child?('blah', true).should be_false
      clients.can_have_child?('blah.json', true).should be_false
    end
    it 'child() with existent child returns REST file' do
      clients.child('notachild').dir?.should be_false
    end
    context 'with children' do
      before(:each) do
        @rest.should_receive(:get_rest).with('clients').once.and_return(
          {
            "achild" => "http://opscode.com/achild",
            "bchild" => "http://opscode.com/bchild"
          })
      end
      it 'has correct children' do
        clients.children.map { |child| child.name }.should =~ %w(achild.json bchild.json)
      end
    end
  end
end
