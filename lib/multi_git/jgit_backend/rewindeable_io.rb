# A IO subclass that implements
# rewind for java streams with mark set.
#
# @note This is a Hack
# @note Remember to mark the stream before you build this.
# @api private
class MultiGit::JGitBackend::RewindeableIO < IO
  import "org.jruby.RubyIO"
  import "org.jruby.util.io.OpenFile"
  import "org.jruby.util.io.ChannelStream"
  import "org.jruby.util.io.ChannelDescriptor"
  import "java.nio.channels.Channels"
  def self.new(inputStream)
    jruby_io = RubyIO.new(JRuby.runtime, self)
    jruby_io.openFile.setMainStream(
       ChannelStream.open(
         JRuby.runtime,
         ChannelDescriptor.new(
           Channels.newChannel(inputStream)
         )
       )
     )
    jruby_io.openFile.setMode(OpenFile::READABLE)
    io = JRuby.dereference(jruby_io)
    io.instance_variable_set(:@backend, inputStream)
    return io
  end

  def rewind
    @backend.reset
  end
end

