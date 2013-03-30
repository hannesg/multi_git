require 'multi_git/tree_entry'
module MultiGit

  module Symlink
    include TreeEntry

    def target
      @target ||= read
    end

    def resolve
      parent.traverse(read, :follow => :path)
    end

    def symlink?
      true
    end

  end

end
