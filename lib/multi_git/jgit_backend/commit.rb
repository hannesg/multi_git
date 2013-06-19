require 'multi_git/commit'
require 'multi_git/jgit_backend/object'
module MultiGit
  module JGitBackend
    class Commit < Object
      include MultiGit::Commit

     import 'org.eclipse.jgit.revwalk.RevWalk'

      def parents
        java_commit.parents.map{|pr| repository.read(pr.getId()) }
      end

      def tree
        repository.read(java_commit.tree.id)
      end

      def message
        java_commit.full_message.freeze
      end

      def time
        java_commit.author_ident.when
      end

      def commit_time
        java_commit.committer_ident.when
      end

      def author
        MultiGit::Handle.new(java_commit.author_ident.name,java_commit.author_ident.email_address)
      end

      def committer
        MultiGit::Handle.new(java_commit.committer_ident.name,java_commit.committer_ident.email_address)
      end

      memoize :parents, :tree, :message, :time, :commit_time, :author, :committer

    private

      def java_commit
        repository.use_reader{|rd| RevWalk.new(rd).parseCommit(java_oid) }
      end

      memoize :java_commit

    end
  end
end
