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
      PACKED_REFS = 'packed-refs'.freeze
      PACKED_REF_LINE = /\A(\h{40}) (\S+)\Z/

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
          # query packed refs
          begin
            packed = IO.read(::File.join(repository.git_dir, PACKED_REFS))
            packed.each_line do |line|
              if line =~ PACKED_REF_LINE
                if $2 == name
                  @target = repository.read($1)
                  break
                end
              end
            end
          rescue Errno::ENOENT
          end
        end
      end
    end
  end
end
