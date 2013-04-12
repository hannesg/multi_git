require 'multi_git/tree_entry'
require 'multi_git/file'
module MultiGit

  class Executeable < File

    def mode
      Utils::MODE_EXECUTEABLE
    end
  end

end
