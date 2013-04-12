require 'multi_git/tree_entry'
require 'multi_git/blob'
module MultiGit

  class File < TreeEntry

    module Base
      def mode
        Utils::MODE_FILE
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
    end

    include Base
  end

end
