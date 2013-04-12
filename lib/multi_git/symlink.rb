require 'multi_git/tree_entry'
module MultiGit

  class Symlink < TreeEntry

    module Base

      def target
        object.content
      end

      def resolve
        parent.traverse(target, :follow => :path)
      end
    end

    class Builder < TreeEntry::Builder

      include Base

      def make_inner(inner)
        inner.to_builder
      end

      def target=(t)
        object.content = t
      end

    end

    include Base

  end

end
