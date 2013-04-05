require 'multi_git/backend_set'

describe MultiGit::BackendSet, backend_set: true do

  let(:a_backend) do
    b = double("a_backend")
    b.extend(MultiGit::Backend)
    b.stub(:available?){ true }
    b
  end
  let(:a_different_backend) do
    b = double("a_different_backend")
    b.extend(MultiGit::Backend)
    b.stub(:available?){ true }
    b
  end
  let(:an_unavailable_backend) do
    b = double("a_unavailable_backend")
    b.extend(MultiGit::Backend)
    b.stub(:available?){ false }
    b
  end

  it "allows adding and retrieving backend" do
    set = MultiGit::BackendSet.new
    set[:foo] = a_backend
    set[:foo].should == a_backend
    set.priority(:foo).should == 0
  end

  it "allows adding a backend with priority" do
    set = MultiGit::BackendSet.new
    set[:foo, priority: 100] = a_backend
    set[:foo].should == a_backend
    set.priority(:foo).should == 100
  end

  describe '#[]' do

    it 'resolves :best' do
      set = MultiGit::BackendSet.new
      set[:foo] = a_backend
      set[:best].should == a_backend
    end

    it 'passes thru Backends' do
      set = MultiGit::BackendSet.new
      set[ a_backend ].should == a_backend
    end

  end

  describe '#best' do

    it "prefers backends with higher priority" do
      set = MultiGit::BackendSet.new
      set[:foo] = a_backend
      set[:bar, priority: 1] = a_different_backend
      set.best.should == a_different_backend
    end

    it "ignores unavailable backends" do
      set = MultiGit::BackendSet.new
      set[:foo] = a_backend
      set[:bar, priority: 1] = an_unavailable_backend
      set.best.should == a_backend
    end

  end

end
