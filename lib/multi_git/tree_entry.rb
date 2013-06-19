require 'multi_git/utils'
require 'multi_git/object'
require 'multi_git/builder'
require 'multi_git/walkable'
module MultiGit

  base = Class.new

  # @!parse
  #    class TreeEntry < TreeEntry::Base
  #    end
  TreeEntry = Class.new(base)

  # A tree entry is like a {MultiGit::Object} or a {MultiGit::Builder} but it 
  # also has knows it's parent tree.
  class TreeEntry

    Base = superclass

    class Base

      include Walkable

      # @return [String]
      attr :name
      # @return [MultiGit::Tree::Base]
      attr :parent

      extend Utils::AbstractMethods
      extend Utils::Memoizes

      # @!method mode
      #   @abstract
      #   @return [Integer] the git-internal entry mode
      abstract :mode

      # @visibility private
      def initialize(parent, name, inner)
        @parent = parent
        @name = name
        @object = inner
      end

      # @param [MultiGit::Object] parent
      # @return [MultiGit::TreeEntry]
      def with_parent(parent, name = self.name)
        self.class.new(parent, name, @object)
      end

      def path
        if parent.respond_to? :path
          [parent.path,SLASH, name].join
        else
          name
        end
      end

      memoize :path

    end

    class Builder < Base

      include MultiGit::Builder

      # @return [MultiGit::Builder]
      attr :object

      # {include:MultiGit::Builder#>>}
      # @param (see MultiGit::Builder#>>)
      # @return [MultiGit::TreeEntry]
      def >>(repository)
        result = object >> repository
        return repository.read_entry(parent, name, mode, result.oid)
      end

      # @visibility private
      def initialize(parent, name, *args, &block)
        super( parent, name , make_inner(*args) )
        instance_eval(&block) if block
      end

    end

    # @return [MultiGit::Object]
    attr :object

    include MultiGit::Object

    extend Forwardable

    delegate (MultiGit::Object.instance_methods - ::Object.instance_methods) => :object

    def to_builder
      self.class::Builder.new(parent, name, object)
    end

    def inspect
      ['#<', self.class.name,' ',path,' ', oid, '>'].join
    end


  end

end
