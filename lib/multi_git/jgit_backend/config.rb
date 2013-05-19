require 'multi_git/config'
module MultiGit
  module JGitBackend
    class Config

      include MultiGit::Config
      extend Forwardable

      delegate :each => :@config

      def initialize(java_config)
        @java_config = java_config
        @config = DEFAULTS.merge(Hash[to_enum(:each_java).to_a])
      end

    private
      attr :java_config

      def each_java
        each_java_key do |sec, subsec, name|
          yield [sec,subsec,name].compact.join('.'), java_config.getString(sec.to_java, subsec.to_java, name.to_java)
        end
      end

      def each_java_key
        java_config.sections.map do |sec|
          java_config.getNames(sec.to_java, nil.to_java).each do |name|
            yield sec, nil, name
          end
          java_config.getSubsections(sec.to_java).each do |subsec|
            java_config.getNames(sec.to_java, subsec.to_java).each do |name|
              yield sec, subsec, name
            end
          end
        end
      end

    end
  end
end

