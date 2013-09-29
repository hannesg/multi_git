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
        @time ||= date_to_ruby(java_commit.author_ident.when).freeze
      end

      def commit_time
        @time ||= date_to_ruby(java_commit.committer_ident.when).freeze
      end

      def author
        @author ||= MultiGit::Handle.new(java_commit.author_ident.name,java_commit.author_ident.email_address)
      end

      def committer
        @committer ||= MultiGit::Handle.new(java_commit.committer_ident.name,java_commit.committer_ident.email_address)
      end
    private

      def date_to_ruby( date )
        Java::OrgJruby::RubyTime.newTime(JRuby.runtime,Java::OrgJodaTime::DateTime.new(date))
      end

      def java_commit
        @java_commit ||= repository.use_reader{|rd| RevWalk.new(rd).parseCommit(java_oid) }
      end

    end
  end
end
