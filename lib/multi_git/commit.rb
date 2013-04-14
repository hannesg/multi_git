require 'multi_git/utils'
require 'multi_git/handle'
require 'multi_git/builder'
module MultiGit

  module Commit

    module Base
      extend Utils::AbstractMethods

      abstract :message
      abstract :tree
      abstract :parents
      # @return [Time]
      abstract :time
      # @return [Handle]
      abstract :author
      # @return [Time]
      abstract :commit_time
      # @return [Handle]
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

      attr :time
      attr :commit_time

      attr :author
      attr :committer

      attr_writer :author, :committer, :time, :commit_time
      attr_writer :message

      def initialize(from = nil)
        @parents = []
        if from.kind_of? Tree
          @tree = from.to_builder
        elsif from.kind_of? Tree::Builder
          @tree = from
        elsif from.kind_of? Commit
          @tree = from.tree.to_builder
          @parents << from
        end
        @author = nil
        @committer = nil
        @time = @commit_time = Time.now
      end

      def >>(repo)
        new_tree = repo << tree
        new_parents = parents.map{|p| repo.write(p).oid }
        return repo.make_commit(
          :time => time,
          :author => author,
          :commit_time => commit_time,
          :committer => committer,
          :parents => new_parents,
          :tree => new_tree.oid,
          :message => message,
          :update_ref => []
        )
      end

    end

    include Base

  end
end

