module MultiGit

  module Error

    class NotARepository < ArgumentError
      include Error
    end

    class RepositoryNotBare < NotARepository
      include Error
    end

    class RepositoryBare < NotARepository
      include Error
    end

    class InvalidObjectType < ArgumentError
      include Error
    end

    class InvalidReference < ArgumentError
      include Error
    end

    class InvalidTraversal < ArgumentError
      include Error
    end

    class CyclicSymlink < Exception
      include Error
    end

    class AmbiguousReference < InvalidReference
    end

    class BadRevisionSyntax < InvalidReference
    end

    class WrongTypeForMode < Exception
      include Error

      def initialize(expected, actual)
        super("It looks like you expected a #{expected.inspect} but referenced entry is a #{actual.inspect}")
      end
    end

    class NotYetImplemented < NotImplementedError
      include Error
    end

    class Internal < Exception
      include Error
    end

    class ConcurrentRefUpdate < Exception
      include Error
    end

  end

end
