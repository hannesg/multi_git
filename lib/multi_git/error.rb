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

    class EntryDoesNotExist < InvalidTraversal
    end

    class NotADirectory < InvalidTraversal
    end

    class CyclicSymlink < Exception
      include Error
    end

    class AmbiguousReference < InvalidReference
    end

    class BadRevisionSyntax < InvalidReference
    end

    class InvalidReferenceName < ArgumentError
      include Error
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

      def initialize
        super 'Another process has updated the ref you are currently updating.
This is unlikely to be a problem, no data got lost. You may simply retry the update.
If this happens frequently, you may have want to run "git gc" to remove clobber.'
      end
    end

    class DuplicateConfigKey < Exception
      include Error
    end

  end

end
