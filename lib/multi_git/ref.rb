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
             else raise Error::InvalidReferenceTarget, new
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
    module Locking
      def lock_file_path
        ::File.join(repository.git_dir, name + '.lock')
      end

      def acquire_lock
        f = ::File.open(lock_file_path, ::File::CREAT | ::File::RDWR | ::File::EXCL )
        f.flock(::File::LOCK_EX)
        return f
      end

      def release_lock(lock)
        ::File.unlink(lock.path)
        lock.flock(::File::LOCK_UN)
        lock.close
      end

      def ensure_dir!
        FileUtils.mkdir_p(::File.dirname(lock_file_path))
      end

      def file_path
        ::File.join(repository.git_dir, name)
      end
    end

    # @api developer
    class FileUpdater < Updater

    protected

      include Locking

      def open_file!
        mode = ::File::WRONLY | ::File::TRUNC
        3.times do
          begin
            return ::File.open(file_path, mode | ::File::CREAT)
          rescue Errno::EEXIST
          end
          begin
            return ::File.open(file_path, mode)
          rescue Errno::ENOENT
          end
        end
        raise "Unable to open ref file for update"
      end

      def update!( nx )
        str = object_to_ref_str(nx)
        begin
          file = open_file!
          file.puts(str)
          file.flush
        ensure
          file.close if file
        end
      end

      def remove!
        begin
          ::File.unlink(file_path)
        rescue Errno::ENOENT
        end
        begin
          inf   = ::File.open(packed_ref_path, ::File::RDONLY)
          outf  = ::File.open(packed_ref_path, ::File::WRONLY | ::File::TRUNC)
          nb = "#{name}\n"
          inf.each_line do |line|
            next if line.end_with?(nb)
            outf.write(line)
          end
          inf.close
          outf.close
        rescue Errno::ENOENT
        end
      end

      def object_to_ref_str(object)
        case(object)
        when nil              then ''
        when MultiGit::Object then object.oid
        when Ref              then "ref: #{object.name}"
        end
      end

      def packed_ref_path
        ::File.join(repository.git_dir, 'packed-refs')
      end
    end

    # @api developer
    module PessimisticUpdater

      def initialize(*_)
        super
        ensure_dir!
        @lock = acquire_lock
        # safe now
        self.ref = ref.reload
      end

      def update(new)
        nx = super
        if nx
          update!(nx)
        else
          remove!
        end
        return nx
      end

      def destroy!
        release_lock(@lock) if @lock
      end
    end

    # @api developer
    module OptimisticUpdater

      def update(new)
        ensure_dir!
        lock = acquire_lock
        begin
          current = ref.reload.target
          if current != target
            raise Error::ConcurrentRefUpdate
          end
          old = target
          nx = super
          if nx.nil?
            remove!
          else
            update!(nx)
          end
          return nx
        ensure
          release_lock( lock ) if lock
        end
      end
    end

    class OptimisticFileUpdater < FileUpdater
      include OptimisticUpdater
    end

    class PessimisticFileUpdater < FileUpdater
      include PessimisticUpdater
    end

    class RecklessUpdater < Updater
      class << self
        attr :updater
      end

      SUBCLASSES = Hash.new{|hsh,key|
        hsh[key] = Class.new(self) do
          @updater = key
        end
      }

      def update( new )
        pu = self.class.updater.new( ref )
        begin
          pu.update( new )
        ensure
          pu.destroy!
        end
      end
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
      @leaf ||= begin
        ref = self
        loop do
          break ref unless ref.target.kind_of? MultiGit::Ref
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
    # @overload update( lock = :optimistic )
    #   By using the lock param you can control the isolation:
    #  
    #   [:reckless] Updates the reference the hard way. Only locks enough 
    #               to ensure the integrity of the repository and simply 
    #               overwrites concurrent changes.
    #   [:optimistic] If the target is altered during the execution of the
    #                 block, a {MultiGit::Error::ConcurrentRefUpdate} is 
    #                 raised. This is the default as it holds hard locks 
    #                 only as long as necessary while providing pointfull 
    #                 isolation.
    #   [:pessimistic] A lock is acquired and held during the execution of the
    #                  block. Concurrent updates will wait or fail. This is 
    #                  good if the block is not retry-able or very small.
    #
    #   @param lock [:reckless, :optimistic, :pessimistic]
    #   @yield [current_target] Yields the current target and expects the block to return the new target
    #   @yieldparam current_target [MultiGit::Ref, MultiGit::Object, nil] current target
    #   @yieldreturn [MultiGit::Ref, MultiGit::Object, MultiGit::Builder, nil] new target
    #   @return [MultiGit::Ref] The altered ref
    #
    # @overload update( value )
    #
    #   @param value [MultiGit::Commit, MultiGit::Ref, MultiGit::Builder, nil] new target for this ref
    #   @return [MultiGit::Ref] The altered ref
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
    def update( value_or_lock = :optimistic )
      updater = updater_class(block_given?, value_or_lock).new(self)
      updater.update( block_given? ? yield(updater.target) : value_or_lock )
      return reload
    ensure
      updater.destroy! if updater
    end

    # Shorthand for deleting this ref.
    # @return [Ref]
    def delete
      update( nil )
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

    def reckless_updater
      RecklessUpdater::SUBCLASSES[pessimistic_updater]
    end

    def updater_class( block_given, lock )
      if block_given
        case lock
        when :optimistic  then optimistic_updater
        when :pessimistic then pessimistic_updater
        when :reckless    then reckless_updater
        else
          raise ArgumentError, "Locking method must be either :optimistic, :pessimistic or :reckless. You supplied: #{lock.inspect}"
        end
      else
        pessimistic_updater
      end
    end

  end

end
