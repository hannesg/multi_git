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
      if key.kind_of? Numeric
        return make_entry(*raw_entries[key])
      elsif key.kind_of? String
        return self / key
      else
        raise ArgumentError
      end
    end

    def /(key)
      local, rest = key.split('/',2)
      e = raw_entries.find{|name, _, _ , _| name == local }
      raise ArgumentError unless e
      entry = make_entry(*e)
      if rest
        return entry / rest
      else
        return entry
      end
    end

    def each
      return to_enum unless block_given?
      raw_each do |name, mode, oid, type|
        yield make_entry(name, mode, oid, type)
      end
    end

    def raw_each(&block)
      raw_entries.each(&block)
    end

    def raw_entries
      raise Error::NotYetImplemented, "#{self.class}#each_entry"
    end

    def size
      @size ||= raw_entries.size
    end

  protected

    def make_entry(name, mode, oid, tree)
      repository.read_entry(name,mode,oid)
    end

  end
end
