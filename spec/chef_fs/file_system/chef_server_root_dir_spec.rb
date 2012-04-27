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

  shared_examples 'a json rest endpoint' do
    it 'is a directory' do
      endpoint.dir?.should be_true
    end
    it 'exists' do
      endpoint.exists?.should be_true
    end
    it 'can have json files as children' do
      endpoint.can_have_child?('blah.json', false).should be_true
    end
    it 'cannot have non-json files as children' do
      endpoint.can_have_child?('blah', false).should be_false
    end
    it 'cannot have directories as children' do
      endpoint.can_have_child?('blah', true).should be_false
      endpoint.can_have_child?('blah.json', true).should be_false
    end
    it 'child() with existent child returns REST file' do
      endpoint.child('notachild').dir?.should be_false
    end
    context 'with children' do
      before(:each) do
        @rest.should_receive(:get_rest).with(endpoint_name).once.and_return(
          {
            "achild" => "http://opscode.com/achild",
            "bchild" => "http://opscode.com/bchild"
          })
      end
      it 'has correct children' do
        endpoint.children.map { |child| child.name }.should =~ %w(achild.json bchild.json)
      end
    end
  end

  context 'clients in children' do
    let(:endpoint_name) { 'clients' }
    let(:endpoint) { root_dir.children.select { |child| child.name == 'clients' }.first }

    it_behaves_like 'a json rest endpoint'

    it 'parent is root' do
      endpoint.parent.should == root_dir
    end
    it 'has path /clients' do
      endpoint.path.should == '/clients'
    end
    it 'has path_for_printing remote/clients' do
      endpoint.path_for_printing.should == 'remote/clients'
    end
  end

  context 'root.child(clients)' do
    let(:endpoint_name) { 'clients' }
    let(:endpoint) { root_dir.child('clients') }

    it_behaves_like 'a json rest endpoint'

    it 'parent is root' do
      endpoint.parent.should == root_dir
    end
    it 'has path /clients' do
      endpoint.path.should == '/clients'
    end
    it 'has path_for_printing remote/clients' do
      endpoint.path_for_printing.should == 'remote/clients'
    end
  end

  context 'root.child(environments)' do
    let(:endpoint_name) { 'environments' }
    let(:endpoint) { root_dir.child('environments') }

    it_behaves_like 'a json rest endpoint'

    it 'parent is root' do
      endpoint.parent.should == root_dir
    end
    it 'has path /environments' do
      endpoint.path.should == '/environments'
    end
    it 'has path_for_printing remote/environments' do
      endpoint.path_for_printing.should == 'remote/environments'
    end
  end

  context 'root.child(nodes)' do
    let(:endpoint_name) { 'nodes' }
    let(:endpoint) { root_dir.child('nodes') }

    it_behaves_like 'a json rest endpoint'

    it 'parent is root' do
      endpoint.parent.should == root_dir
    end
    it 'has path /nodes' do
      endpoint.path.should == '/nodes'
    end
    it 'has path_for_printing remote/nodes' do
      endpoint.path_for_printing.should == 'remote/nodes'
    end
  end

  context 'root.child(roles)' do
    let(:endpoint_name) { 'roles' }
    let(:endpoint) { root_dir.child('roles') }

    it_behaves_like 'a json rest endpoint'

    it 'parent is root' do
      endpoint.parent.should == root_dir
    end
    it 'has path /roles' do
      endpoint.path.should == '/roles'
    end
    it 'has path_for_printing remote/roles' do
      endpoint.path_for_printing.should == 'remote/roles'
    end
  end
end
