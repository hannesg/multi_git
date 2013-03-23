
describe MultiGit::Backend do

  describe :git do
    it "is available" do
      MultiGit::Backend[:git].should be_available
    end
  end

  describe :jgit do
    if RUBY_ENGINE == 'jruby'
      it "is available" do
        MultiGit::Backend[:jgit].should be_available
      end
    else
      it "is not available" do
        MultiGit::Backend[:jgit].should_not be_available
      end
    end
  end

  describe :rugged do
    if RUBY_ENGINE == 'jruby'
      it "is not available" do
        MultiGit::Backend[:rugged].should_not be_available
      end
    else
      it "is available" do
        MultiGit::Backend[:rugged].should be_available
      end
    end
  end

end
