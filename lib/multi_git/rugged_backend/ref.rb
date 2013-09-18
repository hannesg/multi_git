require 'multi_git/ref'
module MultiGit

  module RuggedBackend

    class Ref

      include MultiGit::Ref

      # @api private
      def initialize(repository, name)
        if name.kind_of? Rugged::Reference
          ref = name
          name = ref.name
        else
          ref = Rugged::Reference.lookup(repository.__backend__, name)
        end
        super(repository, name)
        @rugged_ref = ref
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

      # @api private
      # @visibility private
      attr :rugged_ref

    private
      class Updater < MultiGit::Ref::Updater
        include MultiGit::Ref::Locking
      protected
        def update!(nx)
          Rugged::Reference.create(repository.__backend__, name, object_to_ref_str(nx), true)
        end
        def remove!
          ref.rugged_ref.delete!
        end
        def object_to_ref_str(nx)
          case( nx )
          when MultiGit::Object then nx.oid
          when Ref              then nx.name
          end
        end

        # nerf release_lock, rugged does that for us
        def release_lock(_)
        end
      end

      class OptimisticUpdater < Updater
        include MultiGit::Ref::OptimisticUpdater
      end

      class PessimisticUpdater < Updater
        include MultiGit::Ref::PessimisticUpdater
      end

      def pessimistic_updater
        PessimisticUpdater
      end

      def optimistic_updater
        OptimisticUpdater
      end

    end

  end
end
