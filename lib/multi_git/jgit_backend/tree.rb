require 'multi_git/tree'
require 'multi_git/jgit_backend/object'
module MultiGit::JGitBackend

  class Tree

    include MultiGit::Tree
    include MultiGit::JGitBackend::Object

  end
end
