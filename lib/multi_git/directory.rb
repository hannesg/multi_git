require 'multi_git/tree'
require 'multi_git/tree_entry'
module MultiGit

  class Directory < TreeEntry

    module Base
      def mode
        Utils::MODE_DIRECTORY
      end
      def parent?
        !@parent.nil?
      end
    end

    class Builder < TreeEntry::Builder
      include Tree::Base
      include Tree::Builder::DSL
      include Base

      def make_inner(*args)
        if args.any?
          if args[0].kind_of? Tree::Builder
            return args[0]
          elsif args[0].kind_of? Tree
            return args[0].to_builder
          end
        end
        Tree::Builder.new(*args)
      end

      extend Forwardable

      # TODO: lazify & persist!
      def entries
        Hash[
          object.entries.map{|k,v| [k, v.to_builder.with_parent(self) ] }
        ]
      end

      def entry_set(key, value)
        object.entry_set(key, make_entry(key, value))
      end

    end

    include Tree::Base
    include Base

    def to_builder
      Builder.new(parent, name, self)
    end

    include MultiGit::Tree

    extend Forwardable

    def entries
      @entries ||= Hash[
        object.entries.map{|k,v| [k, v.with_parent(self) ] }
      ]
    end

  end

end
