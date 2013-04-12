require 'multi_git/tree_entry'
module MultiGit

  class Symlink < TreeEntry

    def target
      object.content
    end

    def resolve
      parent.traverse(target, :follow => :path)
    end

  end

end
