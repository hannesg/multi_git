require 'multi_git/blob'
require 'multi_git/git_backend/object'
module MultiGit::GitBackend

  class Blob < IO

    include MultiGit::Blob
    include MultiGit::GitBackend::Object

    delegate (IO.public_instance_methods-::Object.public_instance_methods) => 'to_io'

    def size
      @size ||= begin
        if @content
          @content.bytesize
        else
          @git.simple('cat-file',:s,@oid)[1].to_i
        end
      end
    end

    def content
      @content ||= @git.simple('cat-file','blob',@oid)[1].freeze
    end

    private :content

    def to_io
      @io ||= StringIO.new(content)
    end

  end

end
