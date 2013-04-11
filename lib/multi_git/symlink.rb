require 'multi_git/tree_entry'
module MultiGit

  module Symlink
    include TreeEntry

    def target
      content
    end

    def resolve
      parent.traverse(target, :follow => :path)
    end

    def symlink?
      true
    end

  end

end
