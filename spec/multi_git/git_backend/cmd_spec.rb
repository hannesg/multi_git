require 'multi_git/git_backend/cmd'
describe MultiGit::GitBackend::Cmd, cmd: true do

  Cmd = MultiGit::GitBackend::Cmd

  it "barfs correctly" do
    expect{
      Cmd.new('/bin/bash').call do |stdin, stdout|
        stdin.write('exit 1')
        stdin.close
      end
    }.to raise_error(Cmd::Error::ExitCode1)
  end

  it "handles stderr" do
    expect{
      Cmd.new('/bin/bash').call do |stdin, stdout|
        stdin.write('echo "foo" 1>&2; exit 2')
        stdin.close
      end
    }.to raise_error(Cmd::Error::ExitCode2, "foo")
  end

  it "passes the block result" do
    object = Object.new
    result = Cmd.new('/bin/bash').call do |stdout|
               object
             end
    result.should == object
  end

  it "yields stdout if called with a unary block" do
    expect{|yld|
      Cmd.new('/bin/echo').call("foo") do |stdout|
        yld.to_proc.call(stdout)
      end
    }.to yield_with_args(IO)
  end

  it "emtpies the env" do
    Cmd.new('/usr/bin/env').call.should == ""
  end

  it "set env variables" do
    Cmd.new('/usr/bin/env').call_env({'FOO'=>'BAR'}).should == "FOO=BAR\n"
  end

end
