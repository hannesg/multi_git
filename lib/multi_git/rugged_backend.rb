require 'rugged'
module MultiGit
  module RuggedBackend
    class << self

      def load!
      end

      def open(path, options = {})
        Repository.new(path, options)
      end

    end
  end
end
require 'multi_git/rugged_backend/repository'
