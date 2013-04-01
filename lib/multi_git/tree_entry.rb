require 'multi_git/utils'
require 'multi_git/object'
module MultiGit

  module TreeEntry

    include MultiGit::Object

    attr :name
    attr :mode
    attr :parent

    def initialize(parent, name, *args, &block)
      @parent = parent
      @name = name
      super(*args, &block)
    end

    def symlink?
      false
    end

    def with_parent(p)
      dup.instance_eval do
        @parent = p
        return self
      end
    end

  end

end
