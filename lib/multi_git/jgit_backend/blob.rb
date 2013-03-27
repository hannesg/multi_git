require 'multi_git/blob'
require 'multi_git/jgit_backend/object'
module MultiGit::JGitBackend

  class Blob < IO

    include MultiGit::Blob
    include MultiGit::JGitBackend::Object

    delegate (IO.public_instance_methods-::Object.public_instance_methods) => 'to_io'

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
  end
end
