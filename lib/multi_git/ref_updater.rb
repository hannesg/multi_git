module MultiGit

  module RefUpdate

    def initialize(repository, ref, mode = :optimistic)
      @repository = repository
      @mode = mode
    end

    def acquire(ref)
      @refs[ref] = @repository.parse(ref)
    end

    def update(new_oid)

    end

    def call
      update(yield)
    end

  end

end
