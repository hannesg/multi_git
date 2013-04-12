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

      def make_inner(*args)
        if args.any?
          if args[0].kind_of? Blob::Builder
            return args[0]
          elsif args[0].kind_of? Blob
            return args[0].to_builder
          end
        end
        Blob::Builder.new(*args)
      end

      def target=(t)
        object.content = t
      end

    end

    include Base

  end

end
