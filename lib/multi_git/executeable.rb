require 'multi_git/tree_entry'
module MultiGit

  module Executeable
    include TreeEntry

    def mode
      Utils::MODE_EXECUTEABLE
    end
  end

end
