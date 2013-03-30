require 'multi_git/utils'
require 'multi_git/object'
module MultiGit

  module TreeEntry

    include MultiGit::Object

    attr :name
    attr :mode
    attr :parent

    def initialize(parent, name, mode,*args, &block)
      @parent = parent
      @name = name
      @mode = mode
      super(*args, &block)
    end

    def symlink?
      false
    end

  end

end
