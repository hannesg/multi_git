require 'multi_git/object'
module MultiGit
  module Blob

    include MultiGit::Object

    def blob?
      true
    end

    def type
      :blob
    end

  end
end
