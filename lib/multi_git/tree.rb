require 'multi_git/object'
require 'forwardable'
module MultiGit
  module Tree

    SLASH = '/'.freeze

    include MultiGit::Object
    include Enumerable

    def tree?
      true
    end

    def type
      :tree
    end

    def parent?
      false
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

    def [](key, options = {})
      if key.kind_of? Integer
        e = raw_entries[key]
        raise ArgumentError, "Index #{key.to_s} out of bounds. The tree #{self.inspect} has only #{size} elements." unless e
        return make_entry(*e)
      elsif key.kind_of? String
        return traverse(key, options)
      else
        raise ArgumentError, "Expected an Integer or a String, got a #{key.inspect}"
      end
    end

    def entry(key)
      e = raw_entries_by_name[key]
      return nil unless e
      return make_entry(*e)
    end

    def traverse(path, options = {})
      parts = path.split('/').reverse!
      current = self
      follow = options.fetch(:follow){true}
      oids = Set.new
      while parts.any?
        part = parts.pop
        raise MultiGit::Error::InvalidTraversal, "Can't traverse to #{path} from #{self.inspect}: #{current.inspect} doesn't contain an entry named #{part.inspect}" unless current.tree?
        if part == '..'
          unless current.parent?
            raise MultiGit::Error::InvalidTraversal, "Can't traverse to parent of #{current.inspect} since I don't know where it is."
          end
          current = current.parent
        elsif part == '.' || part == ''
          # do nothing
        else
          entry = current.entry(part)
          raise MultiGit::Error::InvalidTraversal, "Can't traverse to #{path} from #{self.inspect}: #{current.inspect} doesn't contain an entry named #{part.inspect}" unless entry
          # may be a symlink
          if entry.symlink?
            if oids.include? entry.oid
              # We have already seen this symlink
              #TODO: it's okay to see a symlink twice if requested
              raise MultiGit::Error::CyclicSymlink, "Cyclic symlink detected while traversing #{path} from #{self.inspect}."
            else
              oids << entry.oid
            end
            if follow
              parts.push(*entry.target.split(SLASH))
            else
              if parts.none?
                return entry
              else
                raise ArgumentError, "Can't follow symlink #{entry.inspect} since you didn't allow me to"
              end
            end
          else
            current = entry
          end
        end
      end
      return current
    end

    alias / traverse

    def each
      return to_enum unless block_given?
      raw_each do |name, mode, oid|
        yield make_entry(name, mode, oid)
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

    def inspect
      ['#<',self.class.name,' ',oid,' repository:', repository.inspect,'>'].join
    end

  protected

    def make_entry(name, mode, oid)
      repository.read_entry(self, name,mode,oid)
    end

    def raw_entries_by_name
      @raw_entries_by_name ||= Hash[ raw_entries.map{|name, mode, oid| [name,[name, mode, oid]] }]
    end

  end
end
