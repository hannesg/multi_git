require 'fileutils'
require 'tmpdir'
require 'tempfile'
require 'timeout'
shared_examples "a MultiGit blob instance" do

  it "is recognized as a Git::Blob" do
    make_blob("Use all the git!").should be_a(MultiGit::Blob)
  end

  it "is readeable" do
    make_blob("Use all the git!").content.should be_a(String)
  end

  it "has frozen content" do
    make_blob("Use all the git!").content.should be_frozen
  end

  it "returns different ios" do
    blob = make_blob("Use all the git!")
    io1 = blob.to_io
    io1.read.should == "Use all the git!"
    io1.read.should == ""
    io2 = blob.to_io
    io2.read.should == "Use all the git!"
    io1.read.should == ""
  end

  it "returns rewindeable ios" do
    blob = make_blob("Use all the git!")
    io = blob.to_io
    io.read.should == "Use all the git!"
    io.read.should == ""
    io.rewind
    io.read.should == "Use all the git!"
    io.read.should == ""
  end

  it "has the correct size" do
    blob = make_blob("Use all the git!")
    blob.bytesize.should == 16
  end
end

shared_examples "an empty repository" do

  it "can add a blob from string" do
    result = repository.write("Blobs", :blob)
    result.should be_a(MultiGit::Blob)
    result.oid.should == 'b4abd6f716fef3c1a4e69f37bd591d9e4c197a4a'
  end

  it "behaves nice if an object is already present" do
    repository.write("Blobs", :blob)
    result = repository.write("Blobs", :blob)
    result.should be_a(MultiGit::Blob)
    result.oid.should == 'b4abd6f716fef3c1a4e69f37bd591d9e4c197a4a'
  end

  it "can add a blob from an IO ducktype" do
    io = double("io")
    io.should_receive(:read).and_return "Blobs"
    result = repository.write(io, :blob)
    result.should be_a(MultiGit::Blob)
    result.oid.should == 'b4abd6f716fef3c1a4e69f37bd591d9e4c197a4a'
  end

  it "can add a blob from a file ducktype" do
  begin
    tmpfile = Tempfile.new('multi_git')
    tmpfile.write "Blobs"
    tmpfile.rewind
    result = repository.write(tmpfile, :blob)
    result.should be_a(MultiGit::Blob)
    result.oid.should == 'b4abd6f716fef3c1a4e69f37bd591d9e4c197a4a'
  ensure
    File.unlink tmpfile.path if tmpfile
  end
  end

  it "can add a blob from a blob ducktype" do
    blob = double("blob")
    blob.extend(MultiGit::Object)
    blob.extend(MultiGit::Blob)
    blob.stub(:oid){ 'b4abd6f716fef3c1a4e69f37bd591d9e4c197a4a' }
    blob.should_receive(:to_io).and_return StringIO.new("Blobs")
    result = repository.write(blob)
    result.should be_a(MultiGit::Blob)
    result.oid.should == 'b4abd6f716fef3c1a4e69f37bd591d9e4c197a4a'
  end

  it "short-circuts adding an already present blob" do
    blob = double("blob")
    blob.extend(MultiGit::Object)
    blob.extend(MultiGit::Blob)
    blob.stub(:oid){ 'b4abd6f716fef3c1a4e69f37bd591d9e4c197a4a' }
    blob.should_not_receive(:read)
    repository.write("Blobs")
    result = repository.write(blob)
    result.should be_a(MultiGit::Blob)
    result.oid.should == 'b4abd6f716fef3c1a4e69f37bd591d9e4c197a4a'
  end

  it "can add a File::Builder" do
    fb = MultiGit::File::Builder.new(nil, "a", "Blobs")
    result = repository.write(fb)
    result.should be_a(MultiGit::File)
    result.name.should == 'a'
    result.oid.should ==  'b4abd6f716fef3c1a4e69f37bd591d9e4c197a4a'
  end

  it "can add a Tree::Builder" do
    tb = MultiGit::Tree::Builder.new do
      file "a", "b"
      directory "c" do
        file "d", "e"
      end
    end
    result = repository.write(tb)
    result.should be_a(MultiGit::Tree)
    result['a'].should be_a(MultiGit::File)
    result['c'].should be_a(MultiGit::Directory)
    result['c/d'].should be_a(MultiGit::File)
    result.oid.should ==  'b490aa5179132fe8ea44df539cf8ede23d9cc5e2'
  end

  it "can read a previously added blob" do
    inserted = repository.write("Blobs", :blob)
    object = repository.read(inserted.oid)
    object.should be_a(MultiGit::Blob)
    object.content.should == "Blobs"
    object.bytesize.should == 5
    object.oid.should == inserted.oid
  end

  it "can parse a sha1-prefix to the full oid" do
    inserted = repository.write("Blobs", :blob)
    repository.parse(inserted.oid[0..10]).should == inserted.oid
  end

  it "barfs when trying to read an non-existing oid" do
    expect{
      repository.read("123456789abcdef")
    }.to raise_error(MultiGit::Error::InvalidReference)
  end

  it "can add a simple tree with #make_tree", :make_tree => true do
    oida = repository.write("a").oid
    oidb = repository.write("b").oid
    oidc = repository.write("c").oid
    tree = repository.make_tree([
                                  ['c', 0100644, oidc],
                                  ['a', 0100644, oida],
                                  ['b', 0100644, oidb]
                                ])
    tree.oid.should == "24e88cb96c396400000ef706d1ca1ed9a88251aa"
  end

  it "can add a nested tree with #make_tree", :make_tree => true do
    oida = repository.write("a").oid
    inner_tree = repository.make_tree([
                                  ['a', 0100644, oida],
                                ])
    tree = repository.make_tree([
                                ['tree', 040000, inner_tree.oid]])
    tree.oid.should == "ea743e8d65faf4e126f0d1c4629d1083a89ca6af"
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
      obj = repository.write(content)
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

    it "iterates over the tree" do
      tree = repository.read(tree_oid)
      expect{|yld|
        tree.each(&yld)
      }.to yield_successive_args(
        MultiGit::File,
        MultiGit::Directory)
    end

    it "has the right size" do
      tree.size.should == 2
    end

    it "allows treating the tree as io" do
      begin
        tree.to_io.read.bytes.to_a.should == [49, 48, 48, 54, 52, 52, 32, 98, 97, 114, 0, 37, 124, 197, 100, 44, 177, 160, 84, 240, 140, 200, 63, 45, 148, 62, 86, 253, 62, 190, 153, 52, 48, 48, 48, 48, 32, 102, 111, 111, 0, 239, 188, 23, 230, 30, 116, 109, 173, 92, 131, 75, 203, 148, 134, 155, 166, 107, 98, 100, 249]
      rescue NoMethodError => e
        if RUBY_ENGINE == 'rbx' && e.message == "undefined method `ascii?' on nil:NilClass."
          pending "chomp is borked in rubinius"
        end
        raise
      end
    end

    it "allows treating the tree as io" do
      tree.bytesize.should == 61
    end

    describe "#[]" do

      it "allows accessing entries by name" do
        tree['foo'].should be_a(MultiGit::Directory)
      end

      it "allows accessing nested entries" do
        tree['foo/bar'].should be_a(MultiGit::File)
      end

      it "raises an error for an object" do
        expect{ tree[Object.new] }.to raise_error(ArgumentError, /Expected a String/)
      end

    end

    describe "#key?" do
      it "confirms correctly for names" do
        tree.key?('foo').should be_true
      end

      it "declines correctly for names" do
        tree.key?('blub').should be_false
      end

      it "raises an error for objects" do
        expect{ tree.key? Object.new }.to raise_error(ArgumentError, /Expected a String/)
      end
    end

    describe '#/' do

      it "allows accessing entries with a slash" do
        (tree / 'foo').should be_a(MultiGit::Directory)
      end

      it "sets the correct parent" do
        (tree / 'foo').parent.should == tree
      end

      it "allows accessing nested entries with a slash" do
        (tree / 'foo/bar').should be_a(MultiGit::File)
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

    describe '#to_builder' do

      it "creates a builder" do
        tree.to_builder.should be_a(MultiGit::Builder)
      end

      it "contains all entries from the original tree" do
        b = tree.to_builder
        b.size.should == 2
        b['foo'].should be_a(MultiGit::Directory::Builder)
        b['bar'].should be_a(MultiGit::File::Builder)
      end

      it "contains entries with correct parent" do
        b = tree.to_builder
        b.each do |e|
          e.parent.should == b
        end
      end

      it "allows deleting keys" do
        b = tree.to_builder
        b.delete('bar')
        b.size.should == 1
        b.entry('bar').should be_nil
        new_tree = b >> repository
        new_tree.oid.should == "d4ab49e21a8683faa04acb23ba7aa3c1840509a0"
      end

      it "allows deleting nested keys" do
        b = tree.to_builder
        b.delete('foo/bar')
        b['foo'].size.should == 0
        b.entry('foo/bar').should be_nil
        new_tree = b >> repository
        new_tree.oid.should == "907fcde7d35ba60b853b4d78465d2cc36824ec08"
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

    describe '#to_builder' do

      it "gives a builder" do
        b = tree.to_builder
        b['bar', follow: false].should be_a(MultiGit::Symlink::Builder)
      end

      it "gives a builder" do
        b = tree.to_builder
        b['bar'].should be_a(MultiGit::File::Builder)
      end

      it "allows setting the target" do
        b = tree.to_builder
        b.file('buz','Zup')
        b['bar', follow: false].target = "buz"
        b['bar'].name.should == 'buz'
      end

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
      Timeout.timeout(2) do
        expect{
          tree['foo']
        }.to raise_error(MultiGit::Error::CyclicSymlink)
      end
    end

    it "allows traverse it without follow" do
      # This could loop forever, so ...
      Timeout.timeout(2) do
        tree['foo', follow: false].should be_a(MultiGit::Symlink)
      end
    end

    it "raises an error if we try to resolve it" do
      # This could loop forever, so ...
      Timeout.timeout(2) do
        expect{
          tree['foo', follow: false].resolve
        }.to raise_error(MultiGit::Error::CyclicSymlink)
      end
    end

  end

  context "with a repository containing a commit", commit: true do

    before(:each) do
      `mkdir -p #{tempdir}
cd #{tempdir}
env -i git init --bare . > /dev/null
OID=$(echo -n "foo" | env -i git hash-object -w -t blob --stdin )
TOID=$(echo "100644 blob $OID\tfoo" | env -i git mktree)
COID=$(echo "msg" | env -i GIT_COMMITTER_NAME=multi_git GIT_COMMITTER_EMAIL=info@multi.git 'GIT_COMMITTER_DATE=2005-04-07T22:13:13 +0200' GIT_AUTHOR_NAME=multi_git GIT_AUTHOR_EMAIL=info@multi.git 'GIT_AUTHOR_DATE=2005-04-07T22:13:13 +0200' git commit-tree $TOID)
env -i git update-ref refs/heads/master $COID`
    end

    let(:repository){ subject.open(tempdir) }

    def update_master
      `cd #{tempdir}
OID=$(echo -n "foo" | env -i git hash-object -w -t blob --stdin )
TOID=$(echo "100644 blob $OID\tfoo" | env -i git mktree)
COID=$(echo "msg" | env -i GIT_COMMITTER_NAME=multi_git GIT_COMMITTER_EMAIL=info@multi.git GIT_AUTHOR_NAME=multi_git GIT_AUTHOR_EMAIL=info@multi.git git commit-tree $TOID)
env -i git update-ref refs/heads/master $COID 2>&1`
    end

    def commit_builder(*args)
      MultiGit::Commit::Builder.new(*args) do
        message "foo"
        by 'info@multi.git'
        tree['foo'] = 'bar'
        at Time.utc(2012,1,1,12,0,0)
      end
    end

    it "reads the commit" do
      commit = repository.read('refs/heads/master')
      commit.parents.should == []
      commit.tree.should be_a(MultiGit::Tree)
      commit.message.should == "msg\n"
    end

    it "forwards certain methods to the tree" do
      commit = repository.read('master')
      commit['foo'].should be_a(MultiGit::File)
      (commit / 'foo' ).should be_a(MultiGit::File)
    end

    it "allows building a child commit" do
      commit = repository.read('master')
      child = MultiGit::Commit::Builder.new( commit )
      child.tree['foo'].should be_a(MultiGit::File::Builder)
      child.parents[0].should == commit
      child.message = 'foo'
      handle = child.author = child.committer = MultiGit::Handle.new('multi_git','info@multi.git')
      child.time = child.commit_time = Time.utc(2010,1,1,12,0,0)
      nu = child >> repository
      nu.committer.should == handle
      nu.author.should == handle
      nu.time.should == Time.utc(2010,1,1,12,0,0)
      nu.commit_time.should == Time.utc(2010,1,1,12,0,0)
      nu.message.should == 'foo'
      nu.oid.should == "04cd8dc458e3a6f98cd498b18f905c6a4fd30778"
    end

    it "handles refs" do
      head = repository.ref('refs/heads/master')
      head.target.should == repository.read('refs/heads/master')
      head.name.should == 'refs/heads/master'
      head.should be_exists
      head.should_not be_symbolic
    end

    it "refuses wrong refs" do
      expect{
        repository.ref('master')
      }.to raise_error(MultiGit::Error::InvalidReferenceName)
    end

    it "handles non-existing refs" do
      head = repository.ref('refs/heads/foo')
      head.target.should be_nil
      head.should_not be_exists
      head.name.should == 'refs/heads/foo'
    end

    it "creates non-existing refs" do
      head = repository.ref('refs/heads/foo')
      head.update do |target|
        target.should be_nil
        commit_builder target
      end
      head.reload.target.oid.should == '553bfb16f88e60e71f527f91433aa7282066a332'
    end

    it "creates non-existing refs pessimstically" do
      head = repository.ref('refs/heads/foo')
      head.update(:pessimistic) do |target|
        target.should be_nil
        commit_builder target
      end
      head.reload.target.oid.should == '553bfb16f88e60e71f527f91433aa7282066a332'
    end

    it "can lock refs optimistic" do
      head = repository.ref('refs/heads/master')
      head.update do |target|
        commit_builder target
      end
      repository.ref('refs/heads/master').target.oid.should == 'a00f6588c95cf264fb946480494c418371105a26'
    end

    it "can lock refs pessimistic" do
      head = repository.ref('refs/heads/master')
      head.update(:pessimistic) do |target|
        commit_builder target
      end
      repository.ref('refs/heads/master').target.oid.should == 'a00f6588c95cf264fb946480494c418371105a26'
    end

    it "barfs when a ref gets updated during optimistic update" do
      head = repository.ref('refs/heads/master')
      expect{
        head.update do |target|
          update_master
          commit_builder target
        end
      }.to raise_error(MultiGit::Error::ConcurrentRefUpdate)
    end

    it "lets others barf when a ref gets updated during pessimistic update" do
      head = repository.ref('refs/heads/master')
      head.update(:pessimistic) do |target|
        update_master.should =~ /fatal: Unable to create '.+\.lock': File exists./
        $?.exitstatus.should == 128
        commit_builder target
      end
    end

    it "delete refs optimistic" do
      head = repository.ref('refs/heads/master')
      head.update do |target|
        nil
      end
      repository.ref('refs/heads/master').target.should be_nil
    end

    it "can lock refs pessimistic" do
      head = repository.ref('refs/heads/master')
      head.update(:pessimistic) do |target|
        nil
      end
      repository.ref('refs/heads/master').target.should be_nil
    end

    it "can use the commit dsl" do
      master = repository.branch('master')
      master = master.commit do
        tree['bar'] = 'baz'
      end
      master['bar'].content.should == 'baz'
    end

    it "can set symbolic refs" do
      head = repository.ref('HEAD')
      master = repository.ref('refs/heads/master')
      r = head.update do
        master
      end
      r.target.should == master
    end

    it "can set symbolic refs pessimistic" do
      head = repository.ref('HEAD')
      master = repository.ref('refs/heads/master')
      r = head.update(:pessimistic) do
        master
      end
      r.target.should == master
    end

  end

  context "#each_branch" do

    before(:each) do
      `mkdir -p #{tempdir}`
      build = MultiGit::Commit::Builder.new do
        tree['foo'] = 'bar'
      end
      commit = repository << build
      repository.branch('master').update{ commit }
      repository.branch('foo').update{ commit }
      repository.branch('origin/bar').update{ commit }
    end

    let(:repository){ subject.open(tempdir, init: true) }

    it "lists all branches" do
      expect{|yld|
        repository.each_branch(&yld)
      }.to yield_successive_args(MultiGit::Ref,MultiGit::Ref,MultiGit::Ref)
    end

    it "filters by regexp" do
      expect{|yld|
        repository.each_branch(/\Afoo\z/, &yld)
      }.to yield_successive_args(MultiGit::Ref)
    end

    it "lists local branches" do
      expect{|yld|
        repository.each_branch(:local, &yld)
      }.to yield_successive_args(MultiGit::Ref,MultiGit::Ref)
    end

    it "lists remote branches" do
      expect{|yld|
        repository.each_branch(:remote, &yld)
      }.to yield_successive_args(MultiGit::Ref)
    end

  end
end
