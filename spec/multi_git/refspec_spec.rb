require 'multi_git/refspec'
describe MultiGit::RefSpec, :refspec => true do

  let(:parser){ MultiGit::RefSpec::DEFAULT_PARSER }

  describe 'string parsing' do

    it 'works for canonic refspecs' do
      ps = parser['refs/heads/master:refs/remotes/origin/master']
      expect( ps.size ).to eql 1
      p = ps[0]
      expect(p.from).to eql 'refs/heads/master'
      expect(p.to).to eql 'refs/remotes/origin/master'
      expect(p).to_not be_forced
    end

    it 'works for shortened refspecs' do
      expect(parser['master:master']).to eql [MultiGit::RefSpec.new('refs/heads/master','refs/remotes/origin/master')]
    end

    it 'works for null refspecs' do
      expect(parser[':master']).to eql [MultiGit::RefSpec.new(nil,'refs/remotes/origin/master')]
    end

    it 'works for forced stuff' do
      expect(parser['+master:master']).to eql [MultiGit::RefSpec.new('refs/heads/master','refs/remotes/origin/master', true)]
    end

  end

  describe 'hash parsing' do

    it 'works for simple hashes' do
      expect( parser['refs/heads/master' => 'refs/remotes/origin/master'] ).to eql [MultiGit::RefSpec.new('refs/heads/master','refs/remotes/origin/master')]
    end

    it 'works for hashes with :forced' do
      expect( parser['refs/heads/master' => 'refs/remotes/origin/master', forced: true] ).to eql [MultiGit::RefSpec.new('refs/heads/master','refs/remotes/origin/master', true)]
    end

    it 'doens\'t modify the hash' do
      h = {'refs/heads/master' => 'refs/remotes/origin/master', forced: true}
      expect{ parser[h] }.not_to change{ h } 
    end

  end

end
