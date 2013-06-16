require 'multi_git/utils'
require 'fileutils'
module MultiGit

  # A reference is something that points eihter to another reference or to 
  # an {MultiGit::Object}. So the most noteable method of this class is 
  # {#target}.
  #
  # Instances of this classe are immuteable and reuseable. All writing methods 
  # return new instances.
  #
  # @abstract
  module Ref

    # Updates a reference. Different subclasses use different mechanisms 
    # for locking and storing the references. Locks may be acquired in the 
    # constructor and must be released in #destroy! .
    #
    # Updaters are inherently neither threadsafe nor reuseable. This should 
    # , however, not be a problem since they are not allocated by users.
    #
    # @api developer
    # @abstract
    class Updater

      # @return [MultiGit::Object, MultiGit::Ref, nil]
      attr :target

      # @return [MultiGit::Ref]
      attr :ref

      # @return [MultiGit::Repository]
      def repository
        @ref.repository
      end

      # @return [String]
      def name
        @ref.name
      end

      # @param ref [Ref]
      def initialize(ref)
        self.ref = ref
      end

      # Finally carry out the update.
      #
      # @param new [MultiGit::Object, MultiGit::Ref, nil]
      # @return [MultiGit::Object, MultiGit::Ref, nil]
      # @abstract
      def update(new)
        nx = case new
             when Ref, nil then new
             when Object, Builder then repository.write(new)
             else raise
             end
        @target = nx
        return nx
      end

      # Release all resources used by this updater.
      def destroy!
      end

      # @param ref [Ref]
      def ref=(ref)
        @ref = ref
        @target = ref.target
        return ref
      end

    end

    # @api developer
    class FileUpdater < Updater

    protected

      def ensure_dir!
        FileUtils.mkdir_p(::File.dirname(file_path))
      end

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
        when Ref              then "ref: #{object.name}"
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

    # @api developer
    class PessimisticFileUpdater < FileUpdater

      def initialize(*_)
        super
        ensure_dir!
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

    # @api developer
    class OptimisticFileUpdater < FileUpdater

      def update(new)
        ensure_dir!
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
          release_lock( lock ) if lock
        end
      end

    private

    end

    extend MultiGit::Utils::AbstractMethods

    # The full name of this ref e.g. refs/heads/master for the master branch.
    # @return [String]
    attr :name

    # @!attribute [r] target
    #   The target of this ref.
    #   @return [MultiGit::Ref, MultiGit::Object, nil]
    #   @abstract
    abstract :target

    # @return [MultiGit::Repository]
    attr :repository

    # @visibility private
    def initialize(repository, name)
      @repository = repository
      @name = name
    end

    # Rereads this reference from the repository.
    #
    # @return [MultiGit::Ref]
    def reload
      repository.ref(name)
    end

    # Resolves symbolic references and returns the final reference.
    #
    # @return [MultGit::Ref]
    def resolve
      @leaf = begin
        ref = self
        loop do
          break ref unless ref.symbolic?
          ref = ref.target
        end
      end
    end

    # @!group Treeish methods

    def [](name)
      t = resolve.target
      if t
        return t[name]
      end
    end

    alias / []

    def []=(path, options = {}, value)
      resolve.update(options.fetch(:lock, :pessimistic) ) do |commit|
        
      end
    end

    # @!endgroup

    # @!group Utility methods

    def direct?
      name.include?('/')
    end

    def symbolic?
      !direct?
    end

    def detached?
      symbolic? && !target.kind_of?(Ref)
    end

    def exists?
      !target.nil?
    end

    # @!endgroup

    # @!group Writing methods

    # Updates the target of this reference.
    #
    # The new target of this reference is the result of the passed block. If
    # you return nil, the ref will be deleted.
    #
    # By using the lock param you can control the isolation:
    #
    # [:optimistic] If the target is altered during the execution of the
    #               block, a {MultiGit::Error::ConcurrentRefUpdate} is 
    #               raised. This is the default as it holds hard locks 
    #               only as long as necessary while providing pointfull 
    #               isolation.
    # [:pessimistic] A lock is acquired and held during the execution of the
    #                block. Concurrent updates will wait or fail. This is 
    #                good if the block is not retry-able or very small.
    #
    # @param lock [:optimistic, :pessimistic]
    # @yield [current_target] Yields the current target and expects the block to return the new target
    # @yieldparam current_target [MultiGit::Ref, MultiGit::Object, nil] current target
    # @yieldreturn [MultiGit::Ref, MultiGit::Object, nil] new target
    # @return [MultiGit::Ref] The altered ref
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
    def update( lock = :optimistic )
      updater_class = case lock
                when :optimistic  then optimistic_updater
                when :pessimistic then pessimistic_updater
                end
      begin
        updater = updater_class.new(self)
        updater.update( yield(updater.target) )
        return reload
      ensure
        updater.destroy! if updater
      end
    end

    # Shorthand for deleting this ref.
    # @return [Ref]
    def delete
      update(:pessimistic){ nil }
    end

    # Shorthand method to directly create a commit and update the given ref.
    #
    # @example
    #  # setup:
    #  dir = `mktemp -d`
    #  repository = MultiGit.open(dir, init: true)
    #  # insert a commit:
    #  repository.head.commit do
    #    tree['a_file'] = 'some_content'
    #  end
    #  # check result:
    #  repository.head['a_file'].content #=> eql 'some_content'
    #  # teardown:
    #  `rm -rf #{dir}`
    #
    # @option options :lock [:optimistic, :pessimistic] How to lock during the commit.
    # @yield
    # @return [Ref]
    def commit(options = {}, &block)
      resolve.update(options.fetch(:lock, :optimistic)) do |current|
        Commit::Builder.new(current, &block)
      end
      return reload
    end

    #@!endgroup

    # @api private
    # @visibility private
    def hash
      name.hash ^ repository.hash
    end

    # @api private
    # @visibility private
    def eql?(other)
      return false unless other.kind_of? Ref
      name == other.name && repository.eql?(other.repository)
    end

    # @api private
    # @visibility private
    def ==(other)
      eql?(other) && target == other.target
    end

    # @api private
    # @visibility private
    def inspect
      ['<',self.class,' ',repository.inspect,':', name, ' -> ', target.inspect,' >'].join
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
