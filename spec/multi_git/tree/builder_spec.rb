require 'multi_git/tree/builder'
describe MultiGit::Tree::Builder, :tree_builder => true do

  def subject
    MultiGit::Tree::Builder
  end

  it "is awesome" do
    bld = subject.new
  end

  it "can add files" do
    bld = subject.new
    bld.file "foo"
    bld['foo'].should be_a(MultiGit::File::Builder)
    bld['foo'].parent.should == bld
  end

  it "can add directories" do
    bld = subject.new
    bld.directory "foo"
    bld['foo'].should be_a(MultiGit::Directory::Builder)
    bld['foo'].parent.should == bld
  end

  it "can add nested directories" do
    bld = subject.new
    bld.directory "foo" do
      directory "bar"
    end
    bld['foo']['bar'].should be_a(MultiGit::Directory::Builder)
  end

  it "can add nested directories with []=" do
    bld = subject.new
    bld['foo/bar'] = "blob"
    bld['foo']['bar'].should be_a(MultiGit::File::Builder)
  end

  it "doesn't create directories if create: false is supplied" do
    bld = subject.new
    expect{
      bld['foo/bar', create: false] = "blob"
    }.to raise_error(MultiGit::Error::InvalidTraversal, /doesn't contain/)
  end

  it "doesn't overwrite directories" do
    bld = subject.new
    bld.file 'foo'
    expect{
      bld['foo/bar'] = "blob"
    }.to raise_error(MultiGit::Error::InvalidTraversal, /does contain/)
  end

  it "does overwrite directories if specified" do
    bld = subject.new
    bld.file 'foo'
    bld['foo/bar', create: :overwrite] = "blob"
    bld['foo']['bar'].should be_a(MultiGit::File::Builder)
  end

  it "can add links" do
    bld = subject.new
    bld['foo'] = 'blob'
    bld.link('bar', 'foo')
    bld['bar', follow:false].resolve.should == bld['foo']
  end

  it "is nesteable" do
    bld1 = subject.new
    bld1.file 'foo'
    bld2 = subject.new(bld1)
    bld2['foo'].should be_a(MultiGit::File::Builder)
  end

  it "is covers overwritten entries" do
    bld1 = subject.new
    bld1.file 'foo'
    bld2 = subject.new(bld1)
    bld2.directory('foo')
    bld2['foo'].should be_a(MultiGit::Directory::Builder)
    bld2.names.should == ['foo']
  end

end
