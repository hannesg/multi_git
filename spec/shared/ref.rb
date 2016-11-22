describe '#ref', ref: true do

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

  blk = proc do
    before(:each) do
      `mkdir -p #{tempdir}
cd #{tempdir}
env -i git init --bare . > /dev/null
OID=$(echo -n "foo" | env -i git hash-object -w -t blob --stdin )
TOID=$(echo "100644 blob $OID\tfoo" | env -i git mktree)
COID=$(echo "msg" | env -i GIT_COMMITTER_NAME=multi_git GIT_COMMITTER_EMAIL=info@multi.git 'GIT_COMMITTER_DATE=2005-04-07T22:13:13 +0200' GIT_AUTHOR_NAME=multi_git GIT_AUTHOR_EMAIL=info@multi.git 'GIT_AUTHOR_DATE=2005-04-07T22:13:13 +0200' git commit-tree $TOID)
env -i git update-ref refs/heads/master $COID
env -i git update-ref FOO $COID`
    end

    let(:repository){ subject.open(tempdir) }

    it "reads the commit" do
      commit = repository.read('refs/heads/master')
      expect(commit.parents).to eql []
      expect(commit.tree).to be_a(MultiGit::Tree)
      expect(commit.message).to eql "msg\n"
    end

    it "forwards certain methods to the tree" do
      commit = repository.read('master')
      expect(commit['foo']).to be_a(MultiGit::File)
      expect((commit / 'foo' )).to be_a(MultiGit::File)
    end

    it "allows building a child commit" do
      commit = repository.read('master')
      child = MultiGit::Commit::Builder.new( commit )
      expect(child.tree['foo']).to be_a(MultiGit::File::Builder)
      expect(child.parents[0]).to eql commit
      child.message = 'foo'
      handle = child.author = child.committer = MultiGit::Handle.new('multi_git','info@multi.git')
      child.time = child.commit_time = Time.utc(2010,1,1,12,0,0)
      nu = child >> repository
      expect(nu.committer).to eql handle
      expect(nu.author).to eql handle
      expect(nu.time).to eql Time.utc(2010,1,1,12,0,0)
      expect(nu.commit_time).to eql Time.utc(2010,1,1,12,0,0)
      expect(nu.message).to eql 'foo'
      expect(nu.oid).to eql "04cd8dc458e3a6f98cd498b18f905c6a4fd30778"
    end

    it "handles refs" do
      head = repository.ref('refs/heads/master')
      expect(head.target).to eql repository.read('refs/heads/master')
      expect(head.name).to eql 'refs/heads/master'
      expect(head).to be_exists
      expect(head).to_not be_symbolic
    end

    it "refuses wrong refs" do
      expect{
        repository.ref('master')
      }.to raise_error(MultiGit::Error::InvalidReferenceName)
    end

    it "handles non-existing refs" do
      head = repository.ref('refs/heads/foo')
      expect(head.target).to be_nil
      expect(head).to_not be_exists
      expect(head.name).to eql 'refs/heads/foo'
    end

    context '.resolve' do
      it "resolves refs" do
        head = repository.ref('FOO')
        expect(head.resolve).to eql head
      end
    end

    context '.update' do

      it "barfs when receiving a unknown symbol" do
        head = repository.ref('refs/heads/master')
        expect{
          head.update(:foo){ }
        }.to raise_error(ArgumentError,/You supplied: :foo/)
      end

      it "barfs when receiving an useable value" do
        head = repository.ref('refs/heads/master')
        expect{
          head.update(:foo)
        }.to raise_error(MultiGit::Error::InvalidReferenceTarget,/You supplied: :foo/)
      end

      it "barfs when the block returns an useable value optimistically" do
        head = repository.ref('refs/heads/master')
        expect{
          head.update{ :foo }
        }.to raise_error(MultiGit::Error::InvalidReferenceTarget,/You supplied: :foo/)
      end

      it "barfs when the block returns an useable value pessimistically" do
        head = repository.ref('refs/heads/master')
        expect{
          head.update(:pessimistic){ :foo }
        }.to raise_error(MultiGit::Error::InvalidReferenceTarget,/You supplied: :foo/)
      end

      it "barfs when the block returns an useable value recklessly" do
        head = repository.ref('refs/heads/master')
        expect{
          head.update(:reckless){ :foo }
        }.to raise_error(MultiGit::Error::InvalidReferenceTarget,/You supplied: :foo/)
      end

      it "creates non-existing refs" do
        head = repository.ref('refs/heads/foo')
        head.update do |target|
          expect(target).to be_nil
          commit_builder target
        end
        expect(head.reload.target.oid).to eql '553bfb16f88e60e71f527f91433aa7282066a332'
      end

      it "creates non-existing refs pessimstically" do
        head = repository.ref('refs/heads/foo')
        head.update(:pessimistic) do |target|
          expect(target).to be_nil
          commit_builder target
        end
        expect(head.reload.target.oid).to eql '553bfb16f88e60e71f527f91433aa7282066a332'
      end

      it "can update refs directly" do
        head = repository.ref('refs/heads/master')
        head.update( commit_builder head.target )
        expect(repository.ref('refs/heads/master').target.oid).to eql 'a00f6588c95cf264fb946480494c418371105a26'
      end

      it "can lock refs optimistic" do
        head = repository.ref('refs/heads/master')
        head.update do |target|
          commit_builder target
        end
        expect(repository.ref('refs/heads/master').target.oid).to eql 'a00f6588c95cf264fb946480494c418371105a26'
      end

      it "can lock refs pessimistic" do
        head = repository.ref('refs/heads/master')
        head.update(:pessimistic) do |target|
          commit_builder target
        end
        expect(repository.ref('refs/heads/master').target.oid).to eql 'a00f6588c95cf264fb946480494c418371105a26'
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
          expect(update_master).to be =~ /fatal:.* Unable to create '.+\.lock': File exists./
          expect($?.exitstatus).to eql 128
          commit_builder target
        end
      end

      it "just overwrites refs with reckless update" do
        head = repository.ref('refs/heads/master')
        head.update(:reckless) do |target|
          update_master
          commit_builder target
        end
        expect(repository.ref('refs/heads/master').target.oid).to eql 'a00f6588c95cf264fb946480494c418371105a26'
      end

      it "delete refs optimistic" do
        head = repository.ref('refs/heads/master')
        head.update do |target|
          nil
        end
        expect(repository.ref('refs/heads/master').target).to be_nil
      end

      it "can delete refs pessimistic" do
        head = repository.ref('refs/heads/master')
        head.update(:pessimistic) do |target|
          nil
        end
        expect(repository.ref('refs/heads/master').target).to be_nil
      end

      it "can delete refs reckless" do
        head = repository.ref('refs/heads/master')
        head.update(:reckless) do |target|
          nil
        end
        expect(repository.ref('refs/heads/master').target).to be_nil
      end

      it "can use the commit dsl" do
        master = repository.branch('master')
        master = master.commit do
          tree['bar'] = 'baz'
        end
        expect(master['bar'].content).to eql 'baz'
      end

      it "can set symbolic refs" do
        head = repository.ref('HEAD')
        master = repository.ref('refs/heads/master')
        r = head.update do
          master
        end
        expect(r.target).to eql master
      end

      it "can set symbolic refs pessimistic" do
        head = repository.ref('HEAD')
        master = repository.ref('refs/heads/master')
        r = head.update(:pessimistic) do
          master
        end
        expect(r.target).to eql master
      end

      it "can detach symbolic refs" do
        head = repository.ref('HEAD')
        target = repository.ref('refs/heads/master').target
        head.update{ target }
        expect(repository.ref('HEAD').target).to eql target
      end
    end

    context '.eql?' do
      it "is true for same ref" do
        expect(repository.ref('HEAD')).to eql repository.ref('HEAD')
      end
      it "is false for differnt ref" do
        expect(repository.ref('HEAD')).to_not eql repository.ref('refs/heads/master')
      end
    end

    context '==' do
      it "is true for same ref" do
        expect(repository.ref('HEAD')).to be == repository.ref('HEAD')
      end
      it "is false for differnt ref" do
        expect(repository.ref('HEAD')).to_not be == repository.ref('refs/heads/master')
      end
    end

    context '.hash' do
      it "is the same for the same ref" do
        expect(repository.ref('HEAD').hash).to eql repository.ref('HEAD').hash
      end
    end

  end

  context "with a repository containing a commit", commit:true, &blk
  context "with a repository containing a commit (packed-ref)", commit:true do
    instance_eval &blk
    before(:each) do
      `cd #{tempdir}; git gc 2> /dev/null`
    end
  end
end
