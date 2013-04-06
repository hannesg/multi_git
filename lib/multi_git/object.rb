require 'multi_git/utils'
module MultiGit
  module Object

    extend Utils::AbstractMethods

    # @return [Repository]
    attr :repository

    # @return [String]
    attr :oid

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

    # @!method to_builder
    #   @abstract
    #   Creates a builder which contains everything this object contains.
    #   @return [MultiGit::Builder] a builder
    abstract :to_builder

    # @!method to_io
    #   @abstract
    #   Returns an IO with the content of this object.
    #   @return [IO]
    abstract :to_io

    # @!method bytesize
    #   @abstract
    #   @return [Integer] size in bytes
    abstract :bytesize

  end
end
