require 'multi_git/blob'
module MultiGit::GitBackend

  class Blob < IO

    include MultiGit::Blob

    delegate (IO.public_instance_methods-Object.public_instance_methods) => 'to_io'

    def initialize(git, oid)
      @git = git
      @oid = oid
    end

    def read
      @content ||= @git.lib.object_contents(@oid).freeze
    end

    def to_io
      @io ||= StringIO.new(content)
    end

  end

end
