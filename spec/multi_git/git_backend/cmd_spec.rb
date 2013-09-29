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
    expect(result).to eql object
  end

  it "yields stdout if called with a unary block" do
    expect{|yld|
      Cmd.new('/bin/echo').call("foo") do |stdout|
        yld.to_proc.call(stdout)
      end
    }.to yield_with_args(IO)
  end

  it "emtpies the env" do
    expect(Cmd.new('/usr/bin/env').call).to eql ""
  end

  it "set env variables" do
    expect(Cmd.new('/usr/bin/env').call_env({'FOO'=>'BAR'})).to eql "FOO=BAR\n"
  end

  it "takes a default env" do
    expect(Cmd.new({'FOO'=>'BAR'}, '/usr/bin/env').call).to eql "FOO=BAR\n"
  end

  it "allows overiding the env" do
    expect(Cmd.new({'FOO'=>'BAR'}, '/usr/bin/env').call_env('FOO'=>'RAB')).to eql "FOO=RAB\n"
  end

end
