require 'multi_git/tree'
require 'multi_git/tree_entry'
module MultiGit

  module Directory

    module Base
      include TreeEntry

      def mode
        Utils::MODE_DIRECTORY
      end

      def parent?
        !@parent.nil?
      end
    end

    class Builder < Tree::Builder
      include Base
    end

    include Base

    def to_builder
      Builder.new(parent, name, self)
    end

  end

end
