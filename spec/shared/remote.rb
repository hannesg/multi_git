describe '#remote', remote: true do

  let(:repository){ subject.open(tempdir, init: true) }

  context 'by url' do

    let(:remote){ repository.remote('git://github.com/git/git.git') }

    it 'works' do
      remote.should be_a(MultiGit::Remote)
    end

    it 'has the correct fetch_url' do
      remote.fetch_urls.should == ['git://github.com/git/git.git']
    end

    it 'has the correct push_url' do
      remote.push_urls.should == ['git://github.com/git/git.git']
    end
  end

  context 'by existing name' do

    before(:each) do
      `cd #{tempdir}; git init --bare ; git remote add origin git://github.com/git/git.git`
    end

    let(:remote){ repository.remote('origin') }

    it 'works' do
      remote.should be_a(MultiGit::Remote::Persistent)
    end

    it 'has the correct name' do
      remote.name.should == 'origin'
    end

    it 'has the correct fetch_url' do
      remote.fetch_urls.should == ['git://github.com/git/git.git']
    end

    it 'has the correct push_url' do
      remote.push_urls.should == ['git://github.com/git/git.git']
    end
  end

end

