require 'fileutils'
require 'tmpdir'
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
      pending if subject == MultiGit::GitBackend
      subject.open(tempdir, :init => true, :bare => true).should be_a(MultiGit::Repository)
      File.exists?(File.join(tempdir,'refs')).should be_true
    end
  end

  context "with a empty repository" do

    before(:each) do
      `env -i git init #{tempdir}`
    end

    it "opens" do
      repo = subject.open(tempdir)
      repo.should be_a(MultiGit::Repository)
    end

  end

  context "with a bare repository" do

    before(:each) do
      `env -i git init --bare #{tempdir}`
    end

    it "opens" do
      repo = subject.open(tempdir)
      repo.should be_a(MultiGit::Repository)
    end

  end

end
