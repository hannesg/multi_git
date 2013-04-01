require 'multi_git/utils'
require 'multi_git/object'
module MultiGit

  module TreeEntry

    attr :name
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

    def >>(repo)
      result = super
      return repo.read_entry(parent, name, mode, result.oid)
    end

  end

end
