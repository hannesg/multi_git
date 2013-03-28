require 'fileutils'
require 'tmpdir'
require 'tempfile'

shared_examples "a MultiGit blob instance" do

  it "is recognized as a Git::Blob" do
    make_blob("Use all the git!").should be_a(MultiGit::Blob)
  end

  it "is recognized as an IO" do
    make_blob("Use all the git!").should be_a(IO)
  end
  it "is readeable" do
    make_blob("Use all the git!").read.should be_a(String)
  end

  it "is rewindeable", focus: true do
    blob = make_blob("Use all the git!")
    blob.read.should == "Use all the git!"
    blob.read.should == ""
    blob.rewind
    blob.read.should == "Use all the git!"
  end

  it "has the correct size" do
    blob = make_blob("Use all the git!")
    blob.size.should == 16
  end
end

shared_examples "an empty repository" do

  it "can add a blob from string" do
    result = repository.put("Blobs", :blob)
    result.should be_a(MultiGit::Blob)
    result.oid.should == 'b4abd6f716fef3c1a4e69f37bd591d9e4c197a4a'
  end

  it "can add a blob from an IO ducktype" do
    io = double("io")
    io.should_receive(:read).and_return "Blobs"
    result = repository.put(io, :blob)
    result.should be_a(MultiGit::Blob)
    result.oid.should == 'b4abd6f716fef3c1a4e69f37bd591d9e4c197a4a'
  end

  it "can add a blob from a file ducktype" do
  begin
    tmpfile = Tempfile.new('multi_git')
    tmpfile.write "Blobs"
    tmpfile.rewind
    result = repository.put(tmpfile, :blob)
    result.should be_a(MultiGit::Blob)
    result.oid.should == 'b4abd6f716fef3c1a4e69f37bd591d9e4c197a4a'
  ensure
    File.unlink tmpfile.path if tmpfile
  end
  end

  it "can read a previously added blob" do
    inserted = repository.put("Blobs", :blob)
    object = repository.read(inserted.oid)
    object.should be_a(MultiGit::Blob)
    object.read.should == "Blobs"
    object.size.should == 5
    object.oid.should == inserted.oid
  end

  it "can parse a sha1-prefix to the full oid" do
    inserted = repository.put("Blobs", :blob)
    repository.parse(inserted.oid[0..10]).should == inserted.oid
  end

  it "barfs when trying to read an oid", :focus => true do
    expect{
      repository.read("123456789abcdef")
    }.to raise_error(MultiGit::Error::InvalidReference)
  end

end

shared_examples "a MultiGit backend" do

  let(:tempdir) do
    Dir.mktmpdir('multi_git')
  end

  after(:each) do
    FileUtils.rm_rf( tempdir )
  end

  context "with an empty directory" do

    it "barfs" do
      expect{
        subject.open(tempdir)
      }.to raise_error(MultiGit::Error::NotARepository)
    end

    it "inits a repository with :init" do
      subject.open(tempdir, :init => true).should be_a(MultiGit::Repository)
      File.exists?(File.join(tempdir,'.git')).should be_true
    end

    it "inits a bare repository with :init and :bare" do
      subject.open(tempdir, :init => true, :bare => true).should be_a(MultiGit::Repository)
      File.exists?(File.join(tempdir,'refs')).should be_true
    end
  end

  context "with an empty repository" do

    before(:each) do
      `env -i git init #{tempdir}`
    end

    let(:repository) do
      subject.open(tempdir)
    end

    it "opens the repo without options" do
      repo = subject.open(tempdir)
      repo.should be_a(MultiGit::Repository)
      repo.should_not be_bare
      repo.git_dir.should == File.join(tempdir, '.git')
      repo.git_work_tree.should == tempdir
    end

    it "opens the repo with :bare => false option" do
      repo = subject.open(tempdir, bare: false)
      repo.should be_a(MultiGit::Repository)
      repo.should_not be_bare
    end

    it "opens the repo with :bare => true option" do
      pending
      repo = subject.open(tempdir, bare: true)
      repo.should be_a(MultiGit::Repository)
      repo.should be_bare
    end

    it_behaves_like "an empty repository"

  end

  context "with an emtpy bare repository" do

    before(:each) do
      `env -i git init --bare #{tempdir}`
    end

    let(:repository) do
      subject.open(tempdir)
    end

    it "opens the repo without options" do
      repo = subject.open(tempdir)
      repo.should be_a(MultiGit::Repository)
      repo.git_dir.should == tempdir
      repo.git_work_tree.should be_nil
      repo.should be_bare
    end

    it "opens the repo with :bare => true option" do
      repo = subject.open(tempdir, bare: true)
      repo.should be_a(MultiGit::Repository)
    end

    it "barfs with :bare => false option" do
      expect{
        subject.open(tempdir, bare: false)
      }.to raise_error(MultiGit::Error::RepositoryBare)
    end

    it_behaves_like "an empty repository"

  end

  context "blob implementation" do

    let(:repository) do
      subject.open(tempdir, init: true)
    end

    def make_blob(content)
      obj = repository.put(content)
      repository.read(obj.oid)
    end

    it_behaves_like "a MultiGit blob instance"

  end

  context "with a repository containing a tiny tree" do

    before(:each) do
      `mkdir -p #{tempdir}
cd #{tempdir}
env -i git init --bare . > /dev/null
OID=$(echo "foo" | env -i git hash-object -w -t blob --stdin )
TOID=$(echo "100644 blob $OID\tbar" | env -i git mktree)
echo "100644 blob $OID\tbar\n040000 tree $TOID\tfoo" | env -i git mktree > /dev/null`
    end

    let(:tree_oid) do
      "95b3dc37df875dfdced5157fa4330d55e6597304"
    end

    let(:repository) do
      subject.open(tempdir)
    end

    it "reads the tree" do
      tree = repository.read(tree_oid)
      tree.should be_a(MultiGit::Tree)
    end

    it "iterates over the tree" do
      tree = repository.read(tree_oid)
      expect{|yld|
        tree.each_entry(&yld)
      }.to yield_successive_args(
        ["bar", 33188, "257cc5642cb1a054f08cc83f2d943e56fd3ebe99", :blob],
        ["foo", 16384, "efbc17e61e746dad5c834bcb94869ba66b6264f9", :tree])
    end
  end

end
