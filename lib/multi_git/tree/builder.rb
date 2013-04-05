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
      @entries[key] = merge_entry(self, name, options[:mode], old, new)
    end

    def >>(repository)
      ent = []
      @entries.each do |name, entry|
        object = repository.put(entry)
        ent << [name, object.mode, object.oid]
      end
      return repository.make_tree(ent)
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
