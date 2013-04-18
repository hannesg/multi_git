require 'multi_git/utils'
module MultiGit

  module Ref

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

    # @!method lock!( mode = :pessimistic )
    #   @param mode [:pessimistic, :optimistic]
    #   @return [Boolean]
    abstract :lock!

    # @!method unlock!
    #   @return [Boolean]
    abstract :unlock!


    # @!method update!( new )
    #   @param new [MultiGit::Ref, MultiGit::Object, nil ]
    abstract :update!

    # @!method canonic_name
    #   @return [String]
    abstract :canonic_name

    def symbolic?
      target.kind_of?(Ref)
    end

    def exists?
      !target.nil?
    end

    # @!method update( mode = 
    #   @yield [MulitGit::Ref, MultiGit::Object, 
    def update
      begin
        lock!
        update!( yield target )
      ensure
        unlock!
      end
    end

  end

end
