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

      def time
        @time ||= java_commit.author_ident.when
      end

      def commit_time
        @time ||= java_commit.committer_ident.when
      end

      def author
        @author ||= MultiGit::Handle.new(java_commit.author_ident.name,java_commit.author_ident.email_address)
      end

      def committer
        @committer ||= MultiGit::Handle.new(java_commit.committer_ident.name,java_commit.committer_ident.email_address)
      end
    private

      def java_commit
        @java_commit ||= repository.use_reader{|rd| RevWalk.new(rd).parseCommit(java_oid) }
      end

    end
  end
end
