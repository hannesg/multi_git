require 'multi_git/commit'
require 'multi_git/rugged_backend/object'
module MultiGit
  module RuggedBackend
    class Commit < Object
      include MultiGit::Commit

      def tree
        repository.read(rugged_object.tree_oid)
      end

      def parents
        rugged_object.parent_oids.map{|oid| repository.read(oid) }
      end

      memoize :tree, :parents

      def author
        MultiGit::Handle.new(rugged_object.author[:name],rugged_object.author[:email])
      end

      def time
        rugged_object.author[:time]
      end

      def committer
        MultiGit::Handle.new(rugged_object.committer[:name],rugged_object.committer[:email])
      end

      def commit_time
        rugged_object.committer[:time]
      end

      def message
        rugged_object.message
      end

    end
  end
end
