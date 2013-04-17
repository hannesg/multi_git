require 'multi_git/ref'
module MultiGit

  module RuggedBackend

    class Ref

      include MultiGit::Ref

      def target
        @target ||= repository.read(rugged_ref.target)
      end

      def canonic_name
        rugged_ref.name
      end

      def exists?
        rugged_ref
      end

      def reload!
        @rugged_loaded = false
        return true
      end

      def update(mode = :optimistic)
        oid = rugged_ref.target

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
