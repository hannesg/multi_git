require 'multi_git/ref'
module MultiGit
  module GitBackend
    class Ref

      include MultiGit::Ref

      def target
        read!
        @target
      end

      def canonic_name
        read!
        @canonic_name
      end

    private
      SHOW_REF_LINE = /\A(\h{40}) ([^\n]+)\Z/.freeze

      def read!
        return if @read
        begin
          @read = true
          lines = repository.__backend__['show-ref', name].lines
          match = SHOW_REF_LINE.match(lines.first)
          @target = repository.read(match[1])
          @canonic_name = match[2]
        rescue Cmd::Error::ExitCode1
          # doesn't exists
          @canonic_name = name
        end
      end
    end
  end
end
