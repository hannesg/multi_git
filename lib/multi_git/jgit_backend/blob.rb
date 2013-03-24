require 'multi_git/blob'
module MultiGit::JGitBackend
  class Blob < IO

    include MultiGit::Blob

    def self.new(git,oid, object = nil)
      java_oid = oid
      java_object = object || git.getObjectDatabase.newReader.open(java_oid)
      oid = Java::OrgEclipseJgitLib::ObjectId.toString(oid)
      jruby_io = Java::OrgJruby::RubyIO.new(JRuby.runtime, self)
      inputStream = java_object.openStream
      jruby_io.openFile.setMainStream(
        Java::OrgJrubyUtilIo::ChannelStream.open(
          JRuby.runtime,
          Java::OrgJrubyUtilIo::ChannelDescriptor.new(
            Java::JavaNioChannels::Channels.newChannel(inputStream)
          )
        )
      )
      jruby_io.openFile.setMode(Java::OrgJrubyUtilIo::OpenFile::READABLE)
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
