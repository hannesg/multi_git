require 'multi_git/object'
require 'forwardable'
module MultiGit
  module Tree

    SLASH = '/'.freeze

    module Base

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
          return entries.key?(key)
        else
          raise ArgumentError, "Expected an Integer or a String, got a #{key.inspect}"
        end
      end

      def [](key, options = {})
        if key.kind_of? Integer
          e = entries.values[key]
          raise ArgumentError, "Index #{key.to_s} out of bounds. The tree #{self.inspect} has only #{size} elements." unless e
          return e
        elsif key.kind_of? String
          return traverse(key, options)
        else
          raise ArgumentError, "Expected an Integer or a String, got a #{key.inspect}"
        end
      end

      def entry(key)
        entries[key]
      end

      def traverse(path, options = {})
        parts = path.split('/').reverse!
        current = self
        follow = options.fetch(:follow){true}
        symlinks = Set.new
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
              if symlinks.include? entry
                # We have already seen this symlink
                #TODO: it's okay to see a symlink twice if requested
                raise MultiGit::Error::CyclicSymlink, "Cyclic symlink detected while traversing #{path} from #{self.inspect}."
              else
                symlinks << entry
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
        entries.each do |name, entry|
          yield entry
        end
      end

      def size
        entries.size
      end

    end

    include Base
    include Object

    def to_builder
      Builder.new(self)
    end

    def inspect
      ['#<',self.class.name,' ',oid,' repository:', repository.inspect,'>'].join
    end

    def entries
      @entries ||= Hash[ raw_entries.map{|name, mode, oid| [name, make_entry(name, mode, oid) ] } ]
    end

  protected
    def raw_entries
      raise Error::NotYetImplemented, "#{self.class}#each_entry"
    end

    def make_entry(name, mode, oid)
      repository.read_entry(self, name,mode,oid)
    end

  end
end
require 'multi_git/tree/builder'
