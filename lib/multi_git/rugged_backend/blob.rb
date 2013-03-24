require 'multi_git/blob'
module MultiGit::RuggedBackend
  class Blob < IO
    include MultiGit::Blob

    def initialize( git, oid )
      @git = git
      @oid = oid
    end

  end
end
