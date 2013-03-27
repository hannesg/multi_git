require 'multi_git/object'
require 'forwardable'
module MultiGit
  module Tree

    include MultiGit::Object
    include Enumerable

    def tree?
      true
    end

    def type
      :tree
    end

    def [](key)
      
    end

    def each
      return to_enum unless block_given?
      each_entry do |name, mode, oid, type|
        yield make_entry(name, mode, oid, type)
      end
    end

    def each_entry
      raise Error::NotYetImplemented, "#{self.class}::each_entry"
    end

    def size
      raise Error::NotYetImplemented, "#{self.class}::size"
    end

  protected

    def make_entry(name, mode, oid, tree)
      repository.read_entry(name,mode,oid)
    end

  end
end
