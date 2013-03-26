require 'multi_git/blob'
module MultiGit::JGitBackend

  class Blob < IO

    include MultiGit::Blob

    delegate (IO.public_instance_methods-Object.public_instance_methods) => 'to_io'

    import "org.eclipse.jgit.lib.ObjectId"

    def initialize(repository,oid, object = nil)
      @repository = repository
      @java_oid = oid
      @git = repository.__backend__
      @oid = ObjectId.toString(oid)
      @java_object = object
    end

    def size
      java_object.getSize
    end

    def rewind
      java_stream.reset
    end

    def to_io
      @io ||= java_stream.to_io
    end

  private

    def java_stream
      @java_stream ||= begin
                         stream = java_object.openStream
                         stream.mark(size)
                         stream
                       end
    end

    def java_object
      @java_object ||= @git.getObjectDatabase.newReader.open(@java_oid)
    end

  end
end
