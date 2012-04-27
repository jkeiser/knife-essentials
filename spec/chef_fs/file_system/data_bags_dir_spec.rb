require 'chef_fs/file_system/chef_server_root_dir'

describe ChefFS::FileSystem::DataBagsDir do
  let(:root_dir) {
    ChefFS::FileSystem::ChefServerRootDir.new('remote',
    {
      :chef_server_url => 'url',
      :node_name => 'username',
      :client_key => 'key',
      :environment => 'env'
    })
  }
  let(:data_bags_dir) { root_dir.child('data_bags') }
  let(:should_list_data_bags) do
    @rest.should_receive(:get_rest).with('data').once.and_return(
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
    data_bags_dir.parent.should == root_dir
  end
  it 'is a directory' do
    data_bags_dir.dir?.should be_true
  end
  it 'exists' do
    data_bags_dir.exists?.should be_true
  end
  it 'has path /data_bags' do
    data_bags_dir.path.should == '/data_bags'
  end
  it 'has path_for_printing remote/data_bags' do
    data_bags_dir.path_for_printing.should == 'remote/data_bags'
  end
  it 'has correct children' do
    should_list_data_bags
    data_bags_dir.children.map { |child| child.name }.should =~ %w(achild bchild)
  end
  it 'can have directories as children' do
    data_bags_dir.can_have_child?('blah', true).should be_true
  end
  it 'cannot have files as children' do
    data_bags_dir.can_have_child?('blah', false).should be_false
  end

end