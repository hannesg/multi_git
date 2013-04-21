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

    class PessimisticFileUpdater < Updater

      def initialize(*_)
        super
        @file = ::File.open(::File.join(repository.git_dir, name),::File::RDWR | ::File::EXCL)
        @file.sync = true
        content = @file.read.chomp
        @target = case content
                  when ''       then nil
                  when /\Aref:/ then repository.ref($`)
                                else repository.read(content)
                  end
      end

      def update(new)
        nx = super
        str = object_to_ref_str(nx)
        @file.rewind
        @file.puts(str)
        return nx
      end

      def destroy!
        @file.close
      end

    private
      def object_to_ref_str(object)
        case(object)
        when nil              then ''
        when MultiGit::Object then object.oid
        when Ref              then "ref:#{object.canonic_name}"
        end
      end
    end

    class OptimisticFileUpdater < Updater

      def update(new)
        file = ::File.open(::File.join(repository.git_dir, name),::File::RDWR | ::File::EXCL)
        file.sync = true
        content = file.read.chomp
        if content != object_to_ref_str(target)
          raise Error::ConcurrentRefUpdate
        end
        nx = super
        str = object_to_ref_str(nx)
        file.rewind
        file.puts(str)
        return nx
      end

    private
      def object_to_ref_str(object)
        case(object)
        when nil              then ''
        when MultiGit::Object then object.oid
        when Ref              then "ref:#{object.canonic_name}"
        end
      end
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

    # @!method update( mode = :optimistic )
    #   @param mode [:optimistic, :pessimistic]
    #   @yield [MultiGit::Ref, MultiGit::Object, nil]
    #   @return [MultiGit::Ref, MultiGit::Object, nil]
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

  private

    def optimistic_updater
      OptimisticFileUpdater
    end

    def pessimistic_updater
      PessimisticFileUpdater
    end

  end

end
