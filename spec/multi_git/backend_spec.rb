require 'multi_git/backend'
describe MultiGit::Backend do

  it "allows adding checks" do
    expect{|yld|
      o = Object.new
      o.instance_eval do
        extend MultiGit::Backend
        check "foo", &yld
      end
      o.available?.should be_true
    }.to yield_with_no_args
  end

  it "marks a check as failed if it returns false" do
    o = Object.new
    o.instance_eval do
      extend MultiGit::Backend
      check "foo" do false end
    end
    o.available?.should be_false
  end

  it "marks a check as failed if it raises an exception" do
    o = Object.new
    o.instance_eval do
      extend MultiGit::Backend
      check "foo" do
        raise "No"
      end
    end
    o.available?.should be_false
    o.exception.should be_a(RuntimeError)
  end

end
