require 'multi_git/commit'
require 'multi_git/jgit_backend/object'
module MultiGit
  module JGitBackend
    class Commit < Object
      include MultiGit::Commit

     import 'org.eclipse.jgit.revwalk.RevWalk'

      def parents
        @parents ||= java_commit.parents.map{|pr| repository.read(pr.getId()) }
      end

      def tree
        @tree ||= repository.read(java_commit.tree.id)
      end

      def message
        @message ||= java_commit.full_message.freeze
      end

    private

      def java_commit
        @java_commit ||= repository.use_reader{|rd| RevWalk.new(rd).parseCommit(java_oid) }
      end

    end
  end
end

