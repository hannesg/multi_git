require 'multi_git/blob'
require 'multi_git/git_backend/object'
module MultiGit::GitBackend

  class Blob < Object

    include MultiGit::Blob

  end

end
