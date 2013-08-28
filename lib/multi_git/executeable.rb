require 'multi_git/tree_entry'
require 'multi_git/file'
module MultiGit

  class Executeable < File

    module Base
      def mode
        Utils::MODE_EXECUTEABLE
      end
    end

    class Builder < File::Builder
      include Base
    end

    include Base
  end

end
