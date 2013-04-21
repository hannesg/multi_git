require 'multi_git/ref'
module MultiGit
  module JGitBackend
    class Ref

      include MultiGit::Ref

      class Java::OrgEclipseJgitStorageFile::RefDirectoryUpdate
        public :tryLock, :unlock, :doUpdate, :doDelete
      end

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
            ru.link( nx.canonic_name )
          end
        end

      end

      class OptimisticUpdater < Updater
        def update(nx)
          ru = repository.__backend__.updateRef(name)
          begin
            if !ru.try_lock(false)
              raise
            end
            old_id = ObjectId.toString(ru.old_object_id)
            if target.nil?
              raise Error::ConcurrentRefUpdate if old_id != Utils::NULL_OID
            elsif old_id != target.oid
              raise Error::ConcurrentRefUpdate
            end
            nx = super
            do_update(ru, nx)
            return nx
          ensure
            ru.unlock
          end
        end

      end

      class PessimisticUpdater < Updater

        def initialize(*_)
          super
          @ref_update = repository.__backend__.updateRef(name)
          if !@ref_update.try_lock(false)
            raise
          end
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

      # @api private
      # @visibility private
      def java_ref
        return @java_ref if @read
        @read = true
        @java_ref = repository.__backend__.getRef(name)
      end

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
