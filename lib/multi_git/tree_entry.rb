require 'multi_git/utils'
require 'multi_git/object'
module MultiGit

  # A tree entry is like a {MultiGit::Object} or a {MultiGit::Builder} but it 
  # also has knows it's parent tree.
  module TreeEntry

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
    def initialize(parent, name, *args, &block)
      @parent = parent
      @name = name
      super(*args, &block)
    end

    # @param [MultiGit::Object] parent
    # @return [MultiGit::TreeEntry]
    def with_parent(parent)
      dup.instance_eval do
        @parent = parent
        return self
      end
    end

    # {include:MultiGit::Builder#>>}
    # @param (see MultiGit::Builder#>>)
    # @return [MultiGit::TreeEntry]
    def >>(repository)
      result = super
      return repository.read_entry(parent, name, mode, result.oid)
    end

  end

end
