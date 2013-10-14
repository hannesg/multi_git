require 'multi_git/utils'
module MultiGit

  # This is a base-module for all objects.
  module Object

    extend Utils::AbstractMethods

    # @return [Repository]
    attr :repository

    # @return [String]
    attr :oid

    # @visibility private
    def hash
      oid.hash
    end

    # @visibility private
    def ==(other)
      if other.respond_to? :oid
        return oid == other.oid
      end
      return false
    end

    # @visibility private
    alias eql? ==

    # @visibility private
    def inspect
      ['#<', self.class.name,' ', oid, '>'].join
    end

    # @!method to_builder
    #   @abstract
    #   Creates a builder which contains everything this object contains.
    #   @return [MultiGit::Builder] a builder
    abstract :to_builder

    # @!method content
    #   @abstract
    #   Returns an String containing the content of this object.
    #   @return [String]
    abstract :content

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
