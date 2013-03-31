require 'multi_git/blob'
require 'multi_git/jgit_backend/object'
module MultiGit::JGitBackend

  class Blob < Object

    include MultiGit::Blob

  end
end
