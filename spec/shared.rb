require 'fileutils'
require 'tmpdir'
require 'tempfile'
require 'timeout'
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

  context "with a repository containing a tiny tree", :tree => true do

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

    let(:tree) do
      tree = repository.read(tree_oid)
    end

    let(:repository) do
      subject.open(tempdir)
    end

    it "reads the tree" do
      tree = repository.read(tree_oid)
      tree.should be_a(MultiGit::Tree)
    end

    it "knows the size" do
      tree = repository.read(tree_oid)
      tree.size.should == 2
    end

    it "iterates over the raw tree entries" do
      tree = repository.read(tree_oid)
      expect{|yld|
        tree.raw_each(&yld)
      }.to yield_successive_args(
        ["bar", 33188, "257cc5642cb1a054f08cc83f2d943e56fd3ebe99"],
        ["foo", 16384, "efbc17e61e746dad5c834bcb94869ba66b6264f9"])
    end

    it "has a list of raw tree entries" do
      tree = repository.read(tree_oid)
      tree.raw_entries.should == [
        ["bar", 33188, "257cc5642cb1a054f08cc83f2d943e56fd3ebe99"],
        ["foo", 16384, "efbc17e61e746dad5c834bcb94869ba66b6264f9"]
      ]
    end

    it "iterates over the tree" do
      tree = repository.read(tree_oid)
      expect{|yld|
        tree.each(&yld)
      }.to yield_successive_args(
        MultiGit::File,
        MultiGit::Directory)
    end

    describe "#[]" do

      it "allows accessing entries by name" do
        tree['foo'].should be_a(MultiGit::Directory)
      end

      it "allows accessing nested entries" do
        tree['foo/bar'].should be_a(MultiGit::File)
      end

      it "raises an error for out-of-bound offset" do
        expect{ tree[2] }.to raise_error(ArgumentError, /Index 2 out of bound/)
      end

      it "raises an error for float offset" do
        expect{ tree[0.5] }.to raise_error(ArgumentError, /Expected an Integer or a String/)
      end

    end

    describe "#key?" do

      it "confirms correctly for integers" do
        tree.key?(0).should be_true
      end

      it "confirms correctly for negative integers" do
        tree.key?(-2).should be_true
      end

      it "declines correctly for integers" do
        tree.key?(2).should be_false
      end

      it "declines correctly for negative integers" do
        tree.key?(-3).should be_false
      end

      it "confirms correctly for names" do
        tree.key?('foo').should be_true
      end

      it "declines correctly for names" do
        tree.key?('blub').should be_false
      end

      it "raises an error for floats" do
        expect{ tree.key? 0.5 }.to raise_error(ArgumentError, /Expected an Integer or a String/)
      end
    end

    describe '#/' do

      it "allows accessing entries with a slash" do
        (tree / 'foo').should be_a(MultiGit::Directory)
      end

      it "allows accessing nested entries with a slash" do
        (tree / 'foo/bar').should be_a(MultiGit::File)
      end

      it "allows accessing entries by offset" do
        tree[0].should be_a(MultiGit::File)
      end

      it "raises an error for missing entry offset" do
        expect{ tree / "blub" }.to raise_error(MultiGit::Error::InvalidTraversal, /doesn't contain an entry named "blub"/)
      end

      it "traverses to the parent tree" do
        (tree / 'foo' / '..').should == tree
      end

      it "raises an error if the parent tree is unknown" do
        expect{
          tree / '..'
        }.to raise_error(MultiGit::Error::InvalidTraversal, /Can't traverse to parent of/)
      end

    end

  end

  context "with a repository containing a simple symlink", :tree => true, :symlink => true do

    before(:each) do
      `mkdir -p #{tempdir}
cd #{tempdir}
env -i git init --bare . > /dev/null
OID=$(echo -n "foo" | env -i git hash-object -w -t blob --stdin )
echo "120000 blob $OID\tbar\n100644 blob $OID\tfoo" | env -i git mktree`
    end

    let(:tree_oid){ "b1210985da34bd8a8d55502b3891fbe5c9f2d7b7" }

    let(:repository){ subject.open(tempdir) }

    let(:tree){ repository.read(tree_oid) }

    it "reads the symlink" do
      tree['bar', follow: false].should be_a(MultiGit::Symlink)
    end

    it "resolves the symlink" do
      target = tree['bar', follow: false].resolve 
      target.should be_a(MultiGit::File)
    end

    it "automatically resolves the symlink" do
      tree['bar'].should be_a(MultiGit::File)
    end

    it "gives a useful error when trying to traverse into the file" do
      expect{
        tree['bar/foo']
      }.to raise_error(MultiGit::Error::InvalidTraversal)
    end

  end

  context "with a repository containing a self-referential symlink", :tree => true, :symlink => true do

    before(:each) do
      `mkdir -p #{tempdir}
cd #{tempdir}
env -i git init --bare . > /dev/null
OID=$(echo -n "foo" | env -i git hash-object -w -t blob --stdin )
echo "120000 blob $OID\tfoo" | env -i git mktree`
    end

    let(:tree_oid){ "12f0253e71b89b95a92128be2844ff6a0c9e6a55" }

    let(:repository){ subject.open(tempdir) }

    let(:tree){ repository.read(tree_oid) }

    it "raises an error if we try to traverse it" do
      # This could loop forever, so ...
      Timeout.timeout(0.2) do
        expect{
          tree['foo']
        }.to raise_error(MultiGit::Error::CyclicSymlink)
      end
    end

    it "allows traverse it without follow" do
      # This could loop forever, so ...
      Timeout.timeout(0.2) do
        tree['foo', follow: false].should be_a(MultiGit::Symlink)
      end
    end

    it "raises an error if we try to resolve it" do
      # This could loop forever, so ...
      Timeout.timeout(0.2) do
        expect{
          tree['foo', follow: false].resolve
        }.to raise_error(MultiGit::Error::CyclicSymlink)
      end
    end

  end
end
