module MultiGit
  module JGitBackend
    class << self

      def load!
      end

      def open(path, options = {})
        Repository.new(path, options)
      end

    end
  end
end
require 'multi_git/jgit_backend/repository'
