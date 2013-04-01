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

    def symlink?
      false
    end

    def hash
      oid.hash
    end

    def eql?(other)
      if other.respond_to? :oid
        return oid == other.oid
      end
      return false
    end

    def ==(other)
      if other.respond_to? :oid
        return oid == other.oid
      end
      return false
    end

    def inspect
      ['#<', self.class.name,' ', oid, '>'].join
    end

  end
end
