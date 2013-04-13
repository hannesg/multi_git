require 'multi_git/utils'
require 'multi_git/builder'
module MultiGit

  module Commit

    module Base
      extend Utils::AbstractMethods

      abstract :message
      abstract :tree
      abstract :parents
      abstract :author
      abstract :committer

      def type
        :commit
      end
    end

    class Builder
      include MultiGit::Builder
      include Base

      attr :message
      attr :tree
      attr :parents

      def initialize
        @tree = Tree::Builder.new
        @parents = []
      end

      def >>(repo)
        new_tree = tree >> repo
        return repo.make_commit(
          :parents => parents,
          :author => author,
          :committer => committer,
          :parents => parents,
          :tree => new_tree.oid,
          :update_ref => []
        )
      end

    end

    include Base

  end
end

