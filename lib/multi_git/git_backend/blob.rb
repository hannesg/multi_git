require 'multi_git/blob'
module MultiGit::GitBackend

  class Blob < IO

    include MultiGit::Blob

    delegate (IO.public_instance_methods-Object.public_instance_methods) => 'to_io'

    def initialize(git, oid, content = nil)
      @git = git
      @oid = oid
      @content = content ? content.dup.freeze : nil
    end

    def size
      @size ||= begin
        if @content
          @content.bytesize
        else
          @git.lib.object_size(@oid)
        end
      end
    end

    def read
      @content ||= @git.lib.object_contents(@oid).freeze
    end

    def to_io
      @io ||= StringIO.new(read)
    end

  end

end
