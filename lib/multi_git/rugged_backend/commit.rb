require 'multi_git/commit'
require 'multi_git/rugged_backend/object'
module MultiGit
  module RuggedBackend
    class Commit < Object
      include MultiGit::Commit

      def tree
        @tree ||= repository.read(rugged_object.tree_oid)
      end

      def parents
        @parents ||= rugged_object.parent_oids.map{|oid| repository.read(oid) }
      end

      def message
        rugged_object.message
      end

    end
  end
end
