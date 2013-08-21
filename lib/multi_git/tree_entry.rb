require 'multi_git/utils'
require 'multi_git/object'
require 'multi_git/builder'
require 'multi_git/walkable'
module MultiGit
  # A tree entry is like a {MultiGit::Object} or a {MultiGit::Builder} but it 
  # also has knows it's parent tree.
  class TreeEntry

    module Base

      include Walkable

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

      def path
        @path ||= begin
                    if parent.respond_to? :path
                      [parent.path,SLASH, name].join
                    else
                      name
                    end
                  end
      end

      def ==(other)
        return false unless other.respond_to?(:path) && other.respond_to?(:object) && other.respond_to?(:mode)
        return (path == other.path) && (object == other.object) && (mode == other.mode)
      end

      def inspect
        ['#<', self.class.name,'@',path,' ', object.inspect, '>'].join
      end
   end

    class Builder# < Base

      include MultiGit::Builder
      include Base

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
    include Base

    extend Forwardable

    delegate [:oid, :content, :to_io, :bytesize] => :object

    def to_builder
      self.class::Builder.new(parent, name, object)
    end


  end

end
