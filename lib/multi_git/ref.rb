module MultiGit

  module Ref

    attr :name
    attr :repository

    def initialize(repository, name)
      @repository = repository
      @name = name
    end

    # @!method reload
    #   @return [MultiGit::Ref]
    abstract :reload

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

  end

end
