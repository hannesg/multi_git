require 'multi_git/backend'
describe MultiGit::Backend do

  it "allows adding checks" do
    expect{|yld|
      o = Object.new
      o.extend(MultiGit::Backend)
      o.check "foo", &yld
      o.available?.should be_true
    }.to yield_with_no_args
  end

  it "marks a check as failed if it returns false" do
    o = Object.new
    o.extend(MultiGit::Backend)
    o.check "foo" do false end
    o.available?.should be_false
  end

  it "marks a check as failed if it raises an exception" do
    o = Object.new
    o.extend(MultiGit::Backend)
    o.check "foo" do
      raise "No"
    end
    o.available?.should be_false
    o.exception.should be_a(RuntimeError)
  end

end
