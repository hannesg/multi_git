require 'multi_git/tree_entry'
module MultiGit

  module Directory
    include TreeEntry

    def parent?
      !@parent.nil?
    end

  end

end
