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

      SHOW_REF_LINE = /\A(\h{40}) ([^\n]+)\Z/.freeze

      def read!
        begin
          if symbolic?
            content = repository.__backend__['symbolic-ref', name]
            @target = repository.ref(content.chomp)
          else
            lines = repository.__backend__['show-ref', name].lines
            match = SHOW_REF_LINE.match(lines.first)
            @target = repository.read(match[1])
          end
        rescue Cmd::Error::ExitCode1
          # doesn't exists
        end
      end
    end
  end
end
