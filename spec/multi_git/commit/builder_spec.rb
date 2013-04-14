require 'multi_git/commit'
describe MultiGit::Commit::Builder, commit_builder:true do

  it "is constructable without anything" do
    commit = described_class.new
    commit.time.should be_a(Time)
    commit.commit_time.should be_a(Time)
    commit.tree.should be_a(MultiGit::Tree::Builder)
  end

  it "allows setting time" do
    commit = described_class.new
    t = commit.time = Time.now
    commit.time.should == t
  end

  it "barfs when setting time to anything but a time"do
    commit = described_class.new
    expect{
      commit.time = "I'm not a time"
    }.to raise_error(ArgumentError, /Expected a Time/)
  end

  it "allows setting commit time" do
    commit = described_class.new
    t = commit.commit_time = Time.now
    commit.commit_time.should == t
  end

  it "barfs when setting commit time to anything but a time"do
    commit = described_class.new
    expect{
      commit.commit_time = "I'm not a time"
    }.to raise_error(ArgumentError, /Expected a Time/)
  end

  it "allows setting the author" do
    commit = described_class.new
    commit.author = MultiGit::Handle.new('name', 'name@example.com')
    commit.author.should == MultiGit::Handle.new('name', 'name@example.com')
  end

  it "allows setting the author with a string" do
    commit = described_class.new
    commit.author = 'name <name@example.com>'
    commit.author.should == MultiGit::Handle.new('name', 'name@example.com')
  end

  it "allows setting the author with an email" do
    commit = described_class.new
    commit.author = 'name@example.com'
    commit.author.should == MultiGit::Handle.new('name@example.com', 'name@example.com')
  end

  it "barfs setting the author to anything" do
    commit = described_class.new
    expect{
      commit.author = Object.new
    }.to raise_error(ArgumentError, /Expected a String or a Handle/)
  end

end
