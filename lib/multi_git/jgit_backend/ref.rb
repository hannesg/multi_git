require 'multi_git/ref'
module MultiGit
  module JGitBackend
    class Ref

      include MultiGit::Ref

      # HACK!
      # @api private
      # @visibility private
      class Java::OrgEclipseJgitStorageFile::RefDirectoryUpdate
        public :tryLock, :unlock, :doUpdate, :doDelete
      end

      # @api developer
      class Updater < MultiGit::Ref::Updater

        import "org.eclipse.jgit.lib.ObjectId"
        import 'org.eclipse.jgit.lib.RefUpdate'

      protected

        def do_update(ru, nx)
          case nx
          when nil then
            ru.doDelete(RefUpdate::Result::FORCED)
          when MultiGit::Object then
            ru.new_object_id = ObjectId.fromString(nx.oid)
            ru.doUpdate(RefUpdate::Result::FORCED)
          when MultiGit::Ref    then
            ru.link( nx.name )
          end
        end

      end

      # @api developer
      class OptimisticUpdater < Updater
        def update(nx)
          ru = repository.__backend__.updateRef(name)
          begin
            if !ru.try_lock(false)
              raise
            end
            if ref.direct?
              old_id = ObjectId.toString(ru.old_object_id)
              if target.nil?
                raise Error::ConcurrentRefUpdate if old_id != Utils::NULL_OID
              elsif old_id != target.oid
                raise Error::ConcurrentRefUpdate
              end
            end
            nx = super
            do_update(ru, nx)
            return nx
          ensure
            ru.unlock
          end
        end

      end

      # @api developer
      class PessimisticUpdater < Updater

        def initialize(*_)
          super
          @ref_update = repository.__backend__.updateRef(name)
          if !@ref_update.try_lock(false)
            raise
          end
          self.ref = ref.reload
        end

        def update(nx)
          nx = super
          do_update(@ref_update, nx)
          return nx
        end

        def destroy!
          @ref_update.unlock
        end
      end

      def initialize(repository, name)
        super(repository, name)
        @java_ref = repository.__backend__.getRef(name)
      end

      def target
        return nil unless java_ref
        @target ||= begin
                    if java_ref.symbolic?
                      repository.ref(java_ref.target.name)
                    else
                      repository.read(java_ref.getObjectId())
                    end
                  end
      end

      # @api private
      # @visibility private
      attr :java_ref

    private

      def optimistic_updater
        OptimisticUpdater
      end

      def pessimistic_updater
        PessimisticUpdater
      end
    end
  end
end
