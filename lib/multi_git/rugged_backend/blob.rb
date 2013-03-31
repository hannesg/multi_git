require 'stringio'
require 'multi_git/blob'
require 'multi_git/rugged_backend/object'
module MultiGit::RuggedBackend
  class Blob < Object
    include MultiGit::Blob
  end
end
