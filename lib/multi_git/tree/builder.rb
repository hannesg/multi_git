require 'multi_git/tree'
require 'multi_git/builder'
module MultiGit
  class Tree::Builder

    include MultiGit::Builder
    include Tree::Base

    attr :entries

    def initialize(from = nil, &block)
      @entries = {}
      instance_eval(&block) if block
    end

    def []=(key, options = {}, value)
      # okay, a bit simple here for now
      parts = key.split('/').reject{|k| k == '' || k == '.' }
      if parts.any?{|p| p == ".." }
        raise MultiGit::Error::InvalidTraversal, "Traversal to parent directories is currently not supported while setting."
      end
      return traverse_set( self, parts, value, true)
    end

    def >>(repository)
      ent = []
      @entries.each do |name, entry|
        object = repository.write(entry)
        ent << [name, object.mode, object.oid]
      end
      return repository.make_tree(ent)
    end

    def entry_set(key, value)
      if value.kind_of? String
        @entries[key] = MultiGit::File::Builder.new(self, key, value)
      elsif value.kind_of? MultiGit::Builder
        @entries[key] = value.with_parent(self)
      else
        raise
      end
    end

    def traverse_set(current, parts, value, create)
      if parts.none?
        raise
      end
      if parts.size == 1
        current.entry_set(parts[0], value)
        return current
      end
      part, *rest = parts
      if !current.respond_to? :entry
        raise MultiGit::Error::InvalidTraversal, "Can't traverse to #{path} from #{self.inspect}: #{current.inspect} doesn't contain an entry named #{part.inspect}"
      end
      entry = current.entry(part)
      if !entry.kind_of? MultiGit::Directory::Builder
        # fine
        if entry.kind_of? MultiGit::Tree
          entry = entry.to_builder
        elsif create == :overwrite || ( entry.nil? && create )
          entry = MultiGit::Directory::Builder.new(current, part)
        else
          raise MultiGit::Error::InvalidTraversal, "Can't traverse to #{path} from #{self.inspect}: #{current.inspect} doesn't contain an entry named #{part.inspect}" unless entry
        end
      end
      current.entry_set(part, traverse_set(entry, rest, value, create))
      return current
    end

    module DSL

      def file(name, content = nil, &block)
        @entries[name] = File::Builder.new(self, name, content, &block)
      end

      def directory(name, &block)
        @entries[name] = Directory::Builder.new(self, name, &block)
      end

    end

    include DSL

  end
end
require 'multi_git/directory'
