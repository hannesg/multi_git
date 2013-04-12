require 'multi_git/utils'
require 'multi_git/object'
require 'multi_git/builder'
module MultiGit

  base = Class.new

  # @!parse
  #    class TreeEntry < TreeEntry::Base
  #    end
  class TreeEntry < base
    Base = superclass
  end

  # A tree entry is like a {MultiGit::Object} or a {MultiGit::Builder} but it 
  # also has knows it's parent tree.
  class TreeEntry

    class Base

      # @return [String]
      attr :name
      # @return [MultiGit::Tree::Base]
      attr :parent

      extend MultiGit::Utils::AbstractMethods

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


  end

end
