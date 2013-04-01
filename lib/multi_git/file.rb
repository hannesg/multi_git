require 'multi_git/tree_entry'
require 'multi_git/blob'
module MultiGit

  module File

    module Base
      include TreeEntry

      def mode
        Utils::MODE_FILE
      end
    end

    class Builder < Blob::Builder
      include Base

      def >>(repo)
        result = super
        return repo.read_entry(parent, name, mode, result.oid)
      end
    end

    include Base

    def to_builder
      Builder.new(self)
    end

  end

end
