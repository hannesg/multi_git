require 'stringio'
require 'multi_git/blob'
module MultiGit::RuggedBackend
  class Blob < IO
    include MultiGit::Blob

    delegate (IO.public_instance_methods-Object.public_instance_methods) => 'to_io'

    def initialize( git, oid, options = {} )
      @git = git
      @oid = oid
      if options[:odb]
        @odb = options[:odb]
      end
    end

    def size
      odb.len
    end

    def to_io
      @io ||= StringIO.new(content)
    end

  private
    def content
      @content ||= odb.data.freeze
    end

    def odb
      @odb ||= @git.read(@oid)
    end

  end
end
