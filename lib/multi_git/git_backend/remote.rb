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

        def fetch_urls
          return repository.config['remote',name,'url']
        end

        def push_urls
          pu = repository.config['remote',name,'pushurl']
          return pu.any? ? pu : fetch_urls
        end

      end

      attr :fetch_urls
      attr :push_urls

      def initialize( repo, url, push_url = url )
        @repository = repo
        @fetch_urls = Array(url)
        @push_urls  = Array(push_url)
      end

    end
  end
end
