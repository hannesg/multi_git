require 'fileutils'
require 'multi_git/ref'
module MultiGit
  module GitBackend
    class Ref

      include MultiGit::Ref

      attr :target

      def initialize(repository, name)
        super(repository, name)
        read!
      end

    private

      SYMBOLIC_REF_LINE = /\Aref: ([a-z0-9_]+(?:\/[a-z0-9_]+)*)\Z/i.freeze
      OID_REF_LINE = /\A(\h{40})\Z/i.freeze

      def read!
        begin
          content = IO.read(::File.join(repository.git_dir,name))
          if content =~ SYMBOLIC_REF_LINE
            @target = repository.ref($1)
          elsif content =~ OID_REF_LINE
            @target = repository.read($1)
          else
            raise content.inspect
          end
        rescue Errno::ENOENT
          # doesn't exists
        end
      end
    end
  end
end
