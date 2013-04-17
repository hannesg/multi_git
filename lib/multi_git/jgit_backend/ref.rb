require 'multi_git/ref'
module MultiGit
  module JGitBackend
    class Ref

      include MultiGit::Ref

      def target
        @target = begin
                    if java_ref.symbolic?
                    else
                      repository.read(java_ref.getObjectId())
                    end
                  end
      end

      def canonic_name
        java_ref.getName
      end

    private

      def java_ref
        @java_ref ||= repository.__backend__.getRef(name)
      end

    end
  end
end
