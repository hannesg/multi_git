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
    bld['foo']['bar'].should be_a(MultiGit::Blob::Builder)
  end

end
