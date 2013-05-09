require 'multi_git/tree'
require 'multi_git/tree_entry'
module MultiGit

  class Directory < TreeEntry

    module Base
      include Tree::Base
      def mode
        Utils::MODE_DIRECTORY
      end

      def parent?
        !@parent.nil?
      end

      def size
        object.size
      end

      def entry(key)
        e = object.entry(key)
        e.with_parent(self) if e
      end

      # @visibility private
      def walk_pre(&block)
        descend = block.call(self)
        return if descend == false
        each do |child|
          child.walk(:pre, &block)
        end
      end

      # @visibility private
      def walk_post(&block)
        each do |child|
          child.walk(:post, &block)
        end
        block.call(self)
      end

      # @visibility private
      def walk_leaves(&block)
        each do |child|
          child.walk(:leaves,&block)
        end
      end
    end

    class Builder < TreeEntry::Builder
      include Tree::Builder::DSL
      include Base

      def make_inner(*args)
        if args.any?
          if args[0].kind_of?(Tree::Builder)
            return args[0]
          elsif args[0].kind_of?(Directory)
            return args[0].object.to_builder
          elsif args[0].kind_of?(Tree)
            return args[0].to_builder
          end
        end
        Tree::Builder.new(*args)
      end

      def entry_set(key, value)
        object.entry_set(key, make_entry(key, value))
      end

      def entries
        Hash[
          object.map{|entry| [entry.name, entry.with_parent(self) ] }
        ]
      end

    end

    include Base

    def entries
      @entries ||= Hash[
        object.map{|entry| [entry.name, entry.with_parent(self) ] }
      ]
    end

  end

end
