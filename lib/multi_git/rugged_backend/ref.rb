require 'multi_git/ref'
module MultiGit

  module RuggedBackend

    class Ref

      include MultiGit::Ref

      def target
        @target ||= rugged_ref && repository.read(rugged_ref.target)
      end

      def canonic_name
        if rugged_ref
          rugged_ref.name
        else
          name
        end
      end

    private

      def rugged_ref
        return @rugged_ref if @rugged_loaded
        @rugged_loaded = true
        return @rugged_ref = repository.__backend__.refs(name).first
      end

    end

  end

end
