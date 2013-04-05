
describe MultiGit do

  describe :git do
    it "is available" do
      MultiGit::GitBackend.should be_available
    end
  end

  describe :jgit do
    if RUBY_ENGINE == 'jruby'
      it "is available" do
        MultiGit::JGitBackend.should be_available
      end
      it "is the best available" do
        MultiGit.best.should == MultiGit::JGitBackend
      end
    else
      it "is not available" do
        MultiGit::JGitBackend.should_not be_available
      end
    end
  end

  describe :rugged do
    if RUBY_ENGINE == 'jruby'
      it "is not available" do
        MultiGit::RuggedBackend.should_not be_available
      end
    else
      it "is available" do
        MultiGit::RuggedBackend.should be_available
      end
      it "is the best available" do
        MultiGit.best.should == MultiGit::RuggedBackend
      end
    end
  end

end
