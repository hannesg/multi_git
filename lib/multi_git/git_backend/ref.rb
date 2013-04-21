require 'fileutils'
require 'multi_git/ref'
module MultiGit
  module GitBackend
    class Ref

      include MultiGit::Ref

      class GitUpdater < Updater

        def update(new)
          old = target
          nx = super
          begin
            if nx.nil?
              return nx if old.nil?
              git['update-ref', '-d', name, target_to_str(old)]
            else
              git['update-ref', '--no-deref', name, target_to_str(nx), target_to_str(old)]
            end
            return nx
          rescue MultiGit::GitBackend::Cmd::Error::ExitCode128
            raise MultiGit::Error::ConcurrentRefUpdate
          end
        end

      private

        NON_EXISTING_TARGET = '0'*40

        def target_to_str(target)
          case(target)
          when nil              then NON_EXISTING_TARGET
          when MultiGit::Object then target.oid
          when MultiGit::Ref    then 'ref:'+target.name
          else raise ArgumentError
          end
        end

        def git
          repository.__backend__
        end

      end

      def target
        read!
        @target
      end

      def canonic_name
        read!
        @canonic_name
      end

    private

      def optimistic_updater
        GitUpdater
      end

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
