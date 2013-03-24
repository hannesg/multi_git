require 'multi_git/object'
require 'forwardable'
module MultiGit
  module Blob

    include MultiGit::Object

    def self.included(base)
      base.extend(Forwardable)
    end

    def blob?
      true
    end

    def type
      :blob
    end

  end
end
