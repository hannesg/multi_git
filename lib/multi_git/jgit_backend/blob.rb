require 'multi_git/blob'
module MultiGit::JGitBackend
  class Blob < IO

    include MultiGit::Blob

    import "org.eclipse.jgit.lib.ObjectId"
    import "org.jruby.RubyIO"
    import "org.jruby.util.io.OpenFile"
    import "org.jruby.util.io.ChannelStream"
    import "org.jruby.util.io.ChannelDescriptor"
    import "java.nio.channels.Channels"

    def self.new(git,oid, object = nil)
      java_oid = oid
      java_object = object || git.getObjectDatabase.newReader.open(java_oid)
      oid = ObjectId.toString(oid)
      jruby_io = RubyIO.new(JRuby.runtime, self)
      inputStream = java_object.openStream
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
      io.instance_eval do
        @git = git
        @oid = oid
        @java_object = java_object
      end
      return io
    end

    def size
      java_object.getSize
    end

    def to_io
      self
    end

  private

    def java_object
      @java_object ||= @git.getObjectDatabase.newReader.open(@java_oid)
    end

  end
end
