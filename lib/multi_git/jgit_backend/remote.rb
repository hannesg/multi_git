require 'multi_git/remote'
module MultiGit
  module JGitBackend
    class Remote

      include MultiGit::Remote

      attr :repository

      class Persistent < self

        include MultiGit::Remote::Persistent

        def initialize( repository, name )
          @repository = repository
          @java_config = Java::OrgEclipseJgitTransport::RemoteConfig.new(repository.config.to_java, name)
        end

        def name
          java_config.getName
        end

      end

      REMOTE_SECTION = 'remote'.to_java
      TEMPORARY_SECTION = 'tmp'.to_java
      FETCH_URL_KEY = 'url'.to_java
      PUSH_URL_KEY = 'pushurl'.to_java

      def initialize( repository, url, push_url = url )
        @repository = repository
        conf = Java::OrgEclipseJgitLib::Config.new
        conf.setString(REMOTE_SECTION, TEMPORARY_SECTION, FETCH_URL_KEY, url)
        conf.setString(REMOTE_SECTION, TEMPORARY_SECTION, PUSH_URL_KEY, push_url)
        @java_config = Java::OrgEclipseJgitTransport::RemoteConfig.new(conf, TEMPORARY_SECTION)
      end

      def fetch_url
        java_config.getURIs.first.to_s
      end

      def push_url
        java_config.getPushURIs.first.to_s
      end

    private

      attr :java_config

    end
  end
end
