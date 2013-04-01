require 'multi_git/tree_entry'
module MultiGit

  module Symlink
    include TreeEntry

    def target
      rewind
      @target ||= read
    end

    def resolve
      parent.traverse(target, :follow => :path)
    end

    def symlink?
      true
    end

  end

end
