require 'multi_git/ref'
module MultiGit

  module RuggedBackend

    class Ref

      include MultiGit::Ref

      def initialize(repository, name)
        super(repository, name)
        @rugged_ref = Rugged::Reference.lookup(repository.__backend__, name)
      end

      def target
        return nil unless rugged_ref
        @target ||= begin
                      if rugged_ref.type == :symbolic
                        repository.ref(rugged_ref.target)
                      else
                        repository.read(rugged_ref.target)
                      end
                    end
      end

    private
      attr :rugged_ref
    end

  end

end
