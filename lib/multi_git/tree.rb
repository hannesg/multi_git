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

    def key?(key)
      if key.kind_of? Integer
        return key >= -size && key < size
      elsif key.kind_of? String
        # TODO: handle "/" in key?
        return raw_entries_by_name.key?(key)
      else
        raise ArgumentError, "Expected an Integer or a String, got a #{key.inspect}"
      end
    end

    def [](key)
      if key.kind_of? Integer
        e = raw_entries[key]
        raise ArgumentError, "Index #{key.to_s} out of bounds. The tree #{self.inspect} has only #{size} elements." unless e
        return make_entry(*e)
      elsif key.kind_of? String
        return self / key
      else
        raise ArgumentError, "Expected an Integer or a String, got a #{key.inspect}"
      end
    end

    def /(key)
      local, rest = key.split('/',2)
      e = raw_entries_by_name.fetch(local) do
        raise ArgumentError, "#{self.inspect} doesn't contain an entry named #{local.inspect}"
      end
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

    def make_entry(name, mode, oid, type)
      repository.read_entry(name,mode,oid)
    end

    def raw_entries_by_name
      @raw_entries_by_name ||= Hash[ raw_entries.map{|name, mode, oid, type| [name,[name, mode, oid, type]] }]
    end

  end
end
