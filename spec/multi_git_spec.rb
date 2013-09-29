
describe MultiGit do

  describe :git do
    it "is available" do
      expect(MultiGit::GitBackend).to be_available
    end
  end

  describe :jgit do
    if RUBY_ENGINE == 'jruby'
      it "is available" do
        expect(MultiGit::JGitBackend).to be_available
      end
      it "is the best available" do
        expect(MultiGit.best).to be MultiGit::JGitBackend
      end
    else
      it "is not available" do
        expect(MultiGit::JGitBackend).not_to be_available
      end
    end
  end

  describe :rugged do
    if (RUBY_ENGINE == 'jruby') || (RUBY_VERSION < "1.9.3")
      it "is not available" do
        expect(MultiGit::RuggedBackend).not_to be_available
      end
    else
      it "is available" do
        expect(MultiGit::RuggedBackend).to be_available
      end
      it "is the best available" do
        expect(MultiGit.best).to be MultiGit::RuggedBackend
      end
    end
  end

  describe '#open' do

    let(:tempdir) do
      Dir.mktmpdir('multi_git')
    end

    after(:each) do
      FileUtils.rm_rf( tempdir )
    end

    it "works" do
      expect(MultiGit.open(tempdir, init: true)).to be_a(MultiGit::Repository)
    end

  end

end
