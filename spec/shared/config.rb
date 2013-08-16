describe '#config', config: true do

  context 'with an empty repository' do

    let(:repository){ described_class.open(tempdir, init: true, bare: true) }

    subject do
      repository.config
    end

    it "is a MultiGit::Config" do
      should be_a(MultiGit::Config)
    end

    it "contains some keys" do
      subject.to_h.should == { ['core',nil,'bare'] => true }
    end

    it "supports hash-access with a qualified key" do
      subject['core.filemode'].should == true
    end

    it "supports hash-access with section and key" do
      subject['core','filemode'].should == true
    end

    it "uses the default for a simple non-existing key" do
      # lets hope git will never have a pirates config ^^
      conf = subject.with_schema(
        MultiGit::Config::Schema.build do
          section "pirates" do
            bool "arrrrr", true
          end
        end
      )
      expect( conf['pirates','arrrrr'] ).to be_true
    end

    it "uses the default for a list non-existing key" do
      conf = subject.with_schema(
        MultiGit::Config::Schema.build do
          section "pirates" do
            array "arrrrr", ['waaaaa']
          end
        end
      )
      expect( conf['pirates','arrrrr'] ).to eql ['waaaaa']
    end

    it 'should support #each' do
      expect{|yld|
        subject.each(&yld)
      }.to yield_with_args(['core',nil,'bare'],true)
    end

    it 'hash-access barfs when called with too many arguments' do
      expect{
        subject['1','2','3','4']
      }.to raise_error(ArgumentError, /(4 for 1..3)/)
    end

    it 'hash-access barfs when called with malformated qualified key' do
      expect{
        subject['key']
      }.to raise_error(ArgumentError, /Expected the qualified key/)
    end

    it "supports writing hash-access with a qualified key" do
      expect{
        subject['core.filemode'] = false
      }.to change{ subject['core','filemode'] }.from(true).to(false)
    end

    it "supports writing hash-access with section and key" do
      expect{
        subject['core','filemode'] = false
      }.to change{ subject['core.filemode'] }.from(true).to(false)
    end

  end

  context 'with a repository containing a list-option' do

    before(:each) do
      `cd #{tempdir}
       git init . --bare
       git config --add remote.origin.url foo@bar.com:baz.git
       git config --add remote.origin.url baz@foo.com:bar.git`
    end

    let(:repository){ described_class.open(tempdir, init: true, bare: true) }

    subject do
      repository.config
    end

    it "lists all values" do
      subject['remote', 'origin', 'url'].should == ['foo@bar.com:baz.git', 'baz@foo.com:bar.git']
    end

    it 'supports #each' do
      expect{|yld|
        subject.each(&yld)
      }.to yield_unordered_args(
        [['core',nil,'bare'],true],
        [['remote', 'origin', 'url'], ['foo@bar.com:baz.git', 'baz@foo.com:bar.git']]
      )
    end

    it "supports setting it to an empty array" do
      expect{
        subject['remote','origin','url'] = []
      }.to change{ subject['remote', 'origin', 'url'] }.from(['foo@bar.com:baz.git', 'baz@foo.com:bar.git']).to([])
    end
  end

  context 'with a repository containing multiple values for a non-list-option' do

    before(:each) do
      `cd #{tempdir}
       git init . --bare
       git config --add core.bare false`
    end

    let(:repository){ described_class.open(tempdir, init: true, bare: true) }

    subject do
      repository.config
    end

    it "takes the last one" do
      pending "See list of inconsistencies" if jgit?
      subject['core', nil, 'bare'].should be_false
    end
  end
end

describe "Config#section", :section => true do

  context 'with a repository containing a remote' do

    before(:each) do
      `cd #{tempdir}
       git init . --bare
       git remote add origin baz@foo.com:bar.git`
    end

    let(:repository){ described_class.open(tempdir, init: true, bare: true) }

    subject do
      repository.config.section('remote', 'origin')
    end

    it "returns a section" do
      expect(subject).to be_a MultiGit::Config::Section
    end

    it "supports hash-access" do
      expect(subject['url']).to eql ['baz@foo.com:bar.git']
    end

    it 'supports #each' do
      expect{|yld|
        subject.each(&yld)
      }.to yield_unordered_args(['fetch','+refs/heads/*:refs/remotes/origin/*'],['url',['baz@foo.com:bar.git']])
    end

    it "supports #to_h" do
      expect(subject.to_h).to eql({'url' => ['baz@foo.com:bar.git'], 'fetch' => '+refs/heads/*:refs/remotes/origin/*'})
    end

  end

end

