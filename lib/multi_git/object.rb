module MultiGit
  module Object

    attr :repository, :oid

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
