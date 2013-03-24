require 'multi_git/blob'
module MultiGit::GitBackend

  class Blob < IO

    include MultiGit::Blob

  end

end
