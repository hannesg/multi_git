require 'multi_git/backend'
describe MultiGit::Backend do

  it "allows adding checks" do
    expect{|yld|
      o = Object.new
      o.instance_eval do
        extend MultiGit::Backend
        check "foo", &yld
      end
      expect(o.available?).to be_true
    }.to yield_with_no_args
  end

  it "marks a check as failed if it returns false" do
    o = Object.new
    o.instance_eval do
      extend MultiGit::Backend
      check "foo" do false end
    end
    expect(o.available?).to be_false
  end

  it "marks a check as failed if it raises an exception" do
    o = Object.new
    o.instance_eval do
      extend MultiGit::Backend
      check "foo" do
        raise "No"
      end
    end
    expect(o.available?).to be_false
    expect(o.exception).to be_a(RuntimeError)
  end

end
