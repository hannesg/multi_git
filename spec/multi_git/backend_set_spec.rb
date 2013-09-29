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
    expect(set[:foo]).to eql a_backend
    expect(set.priority(:foo)).to eql 0
  end

  it "allows adding a backend with priority" do
    set = MultiGit::BackendSet.new
    set[:foo, priority: 100] = a_backend
    expect(set[:foo]).to eql a_backend
    expect(set.priority(:foo)).to eql 100
  end

  describe '#[]' do

    it 'resolves :best' do
      set = MultiGit::BackendSet.new
      set[:foo] = a_backend
      expect(set[:best]).to eql a_backend
    end

    it 'passes thru Backends' do
      set = MultiGit::BackendSet.new
      expect(set[ a_backend ]).to eql a_backend
    end

  end

  describe '#best' do

    it "prefers backends with higher priority" do
      set = MultiGit::BackendSet.new
      set[:foo] = a_backend
      set[:bar, priority: 1] = a_different_backend
      expect(set.best).to eql a_different_backend
    end

    it "ignores unavailable backends" do
      set = MultiGit::BackendSet.new
      set[:foo] = a_backend
      set[:bar, priority: 1] = an_unavailable_backend
      expect(set.best).to eql a_backend
    end

  end

end
