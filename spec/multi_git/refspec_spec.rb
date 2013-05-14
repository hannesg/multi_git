require 'multi_git/refspec'
describe MultiGit::RefSpec do

  describe 'string parsing' do

    it 'works for canonic refspecs' do
      p = MultiGit::RefSpec.parse('refs/heads/master:refs/remotes/origin/master')
      p.from.should == 'refs/heads/master'
      p.to.should == 'refs/remotes/origin/master'
      p.should_not be_forced
    end

    it 'works for shortened refspecs' do
      MultiGit::RefSpec.parse('master:master').should == MultiGit::RefSpec.new('refs/heads/master','refs/remotes/origin/master')
    end

    it 'works for null refspecs' do
      MultiGit::RefSpec.parse(':master').should == MultiGit::RefSpec.new(nil,'refs/remotes/origin/master')
    end

    it 'works for forced stuff' do
      MultiGit::RefSpec.parse('+master:master').should == MultiGit::RefSpec.new('refs/heads/master','refs/remotes/origin/master', true)
    end

  end

  describe 'hash parsing' do

    it 'works for simple hashes' do
      MultiGit::RefSpec.parse('refs/heads/master' => 'refs/remotes/origin/master').should == MultiGit::RefSpec.new('refs/heads/master','refs/remotes/origin/master')
    end

  end

end
