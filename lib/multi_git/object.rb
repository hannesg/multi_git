module MultiGit
  module Object

    attr :oid

    def initialize( git, oid )
      @git = git
      @oid = oid
    end

    def blob?
      false
    end

    def tree?
      false
    end

    def commit?
      false
    end

    def tag?
      false
    end

  end
end
