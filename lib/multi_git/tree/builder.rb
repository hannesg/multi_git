require 'multi_git/tree'
require 'multi_git/builder'
module MultiGit
  class Tree::Builder

    include MultiGit::Builder
    include Tree::Base

    attr :entries

    def initialize(from = nil, &block)
      @entries = {}
    end

    def []=(key, options = {}, value)
      # okay, a bit simple here for now
      @entries[key] = merge_entry(self, name, options[:mode], old, new)
    end

    def >>(repository)
      ent = []
      @entries.each do |name, (mode, content)|
        object = repository.put(content, Utils.type_from_mode(mode))
        ent << [name, mode, object.oid]
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
