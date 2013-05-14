require 'multi_git/remote'
module MultiGit
  module GitBackend
    class Remote
      include MultiGit::Remote

      attr :repository

      class Persistent < self
        include MultiGit::Remote::Persistent

        attr :repository
        attr :name

        def initialize( repo, name )
          @name = name
          @repository = repo
        end

        def fetch_url
          return repository.config["remote.#{name}.url"]
        end

        def push_url
          return repository.config["remote.#{name}.pushurl"] || fetch_url
        end

      end

      attr :fetch_url
      attr :push_url

      def initialize( repo, url, push_url = url )
        @repository = repo
        @fetch_url = url
        @push_url  = push_url
      end

    end
  end
end
