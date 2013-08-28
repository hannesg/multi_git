require 'multi_git/tree_entry'
require 'multi_git/blob'
require 'forwardable'
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

      extend Forwardable

      delegate (Blob::Builder.instance_methods - self.instance_methods) => :object
    end

    include Base
    extend Forwardable

    delegate (Blob.instance_methods - self.instance_methods) => :object
  end

end
