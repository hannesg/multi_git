module MultiGit

  module Ref

    attr :name
    attr :repository

    def initialize(repository, name)
      @repository = repository
      @name = name
    end

  end

end
