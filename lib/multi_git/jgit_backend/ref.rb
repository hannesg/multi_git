require 'multi_git/ref'
module MultiGit
  module JGitBackend
    class Ref

      include MultiGit::Ref

      def target
        return nil unless java_ref
        @target = begin
                    if java_ref.symbolic?
                    else
                      repository.read(java_ref.getObjectId())
                    end
                  end
      end

      def canonic_name
        java_ref ? java_ref.getName : name
      end

    private

      def java_ref
        return @java_ref if @read
        @read = true
        @java_ref = repository.__backend__.getRef(name)
      end

    end
  end
end
