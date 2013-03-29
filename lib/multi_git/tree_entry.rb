require 'multi_git/utils'
require 'multi_git/object'
module MultiGit

  module TreeEntry

    include MultiGit::Object

    attr :name
    attr :mode

    def initialize(name, mode,*args, &block)
      @name = name
      @mode = mode
      super(*args, &block)
    end

  end

end
