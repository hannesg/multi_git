require 'multi_git/tree'
require 'multi_git/git_backend/object'
module MultiGit::GitBackend
  class Tree

    include MultiGit::Tree
    include MultiGit::GitBackend::Object

    def each_entry

    end

  end
end
