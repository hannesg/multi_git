require 'multi_git/utils'
require 'fileutils'
module MultiGit

  module Ref

    class Updater

      attr :target

      def repository
        @ref.repository
      end

      def name
        @ref.canonic_name
      end

      def initialize(ref)
        @ref = ref
        @target = ref.target
      end

      def update(new)
        nx = case new
             when nil then new
             else repository.write(new)
             end
        @target = nx
        return nx
      end

      def destroy!
      end
    end

    class FileUpdater < Updater

    protected

      def open_file(exists)
        mode = ::File::WRONLY | ::File::TRUNC
        if !exists
          begin
            return ::File.open(file_path, mode | ::File::CREAT)
          rescue Errno::EEXIST
            raise Error::ConcurrentRefUpdate
          end
        else
          begin
            return ::File.open(file_path, mode)
          rescue Errno::ENOENT
            raise Error::ConcurrentRefUpdate
          end
        end
      end

      def object_to_ref_str(object)
        case(object)
        when nil              then ''
        when MultiGit::Object then object.oid
        when Ref              then "ref:#{object.canonic_name}"
        end
      end

      def file_path
        ::File.join(repository.git_dir, name)
      end

      def lock_file_path
        ::File.join(repository.git_dir, name + '.lock')
      end

      def acquire_lock
        ::File.open(lock_file_path, ::File::CREAT | ::File::RDWR | ::File::EXCL )
      end

      def release_lock(lock)
        ::File.unlink(lock.path)
        lock.flock(::File::LOCK_UN)
      end

    end

    class PessimisticFileUpdater < FileUpdater

      def initialize(*_)
        super
        @lock = acquire_lock
        # safe now
        @ref = @ref.reload
      end

      def update(new)
        old = target
        nx = super
        if nx
          str = object_to_ref_str(nx)
          begin
            file = open_file(!old.nil?)
            file.puts(str)
            file.flush
          ensure
            file.close if file
          end
        else
          ::File.unlink(file_path)
        end
        return nx
      end

      def destroy!
        release_lock(@lock)
      end

    end

    class OptimisticFileUpdater < FileUpdater

      def update(new)
        begin
          lock = acquire_lock
          if ::File.exists?(file_path)
            content = ::File.read(file_path).chomp
            if content != object_to_ref_str(target)
              raise Error::ConcurrentRefUpdate
            end
          elsif !target.nil?
            raise Error::ConcurrentRefUpdate
          end
          old = target
          nx = super
          if nx.nil?
            if !old
              return nx
            end
            ::File.unlink(file_path)
          else
            begin
              file = open_file( !old.nil? )
              str = object_to_ref_str(nx)
              file.puts( str )
              file.flush
            ensure
              file.close if file
            end
          end
          return nx
        ensure
          release_lock( lock )
        end
      end

    private

    end

    extend MultiGit::Utils::AbstractMethods

    # @return [String]
    attr :name
    # @return [MultiGit::Repository]
    attr :repository

    def initialize(repository, name)
      @repository = repository
      @name = name
    end

    # @return [MultiGit::Ref]
    def reload
      repository.ref(name)
    end

    # @!method target
    #   @return [MultiGit::Ref, MultiGit::Object, nil]
    abstract :target

    # @!method canonic_name
    #   @return [String]
    abstract :canonic_name

    def symbolic?
      target.kind_of?(Ref)
    end

    def exists?
      !target.nil?
    end

    # Updates the target of this ref
    #
    # @param mode [:optimistic, :pessimistic]
    # @yield [current_target] Yields the current target and expects the block to return the new target
    # @yieldparam current_target [MultiGit::Ref, MultiGit::Object, nil] current target
    # @yieldreturn [MultiGit::Ref, MultiGit::Object, nil] new target
    # @return [MultiGit::Ref, MultiGit::Object, nil]
    #
    # @example
    #  # setup:
    #  dir = `mktemp -d`
    #  repository = MultiGit.open(dir, init: true)
    #  # insert a commit:
    #  builder = MultiGit::Commit::Builder.new
    #  builder.tree['a_file'] = 'some_content'
    #  commit = repository.write(builder)
    #  # update the ref:
    #  ref = repository.ref('refs/heads/master') #=> be_a MultiGit::Ref
    #  ref.update do |current_target|
    #    current_target #=> be_nil
    #    commit
    #  end
    #  # check result:
    #  repository.ref('refs/heads/master').target #=> eql commit
    #  # teardown:
    #  `rm -rf #{dir}`
    def update( mode = :optimistic )
      updater_class = case mode
                when :optimistic  then optimistic_updater
                when :pessimistic then pessimistic_updater
                end
      begin
        updater = updater_class.new(self)
        updater.update( yield(updater.target) )
      ensure
        updater.destroy! if updater
      end
    end

    def delete
      update{ nil }
    end

  private

    def optimistic_updater
      OptimisticFileUpdater
    end

    def pessimistic_updater
      PessimisticFileUpdater
    end

  end

end
