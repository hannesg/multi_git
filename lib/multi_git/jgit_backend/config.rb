require 'multi_git/config'
module MultiGit
  module JGitBackend
    class Config

      include MultiGit::Config

      def initialize(java_config)
        @java_config = java_config
      end

      def get(section, subsection, name)
        s = schema_for(section, subsection, name)
        if s.list?
          value = java_config.getStringList(section, subsection, name).to_a
          if value.any?
            return s.convert(value)
          else
            return s.default
          end
        else
          value = java_config.getString(section, subsection, name)
          if value.nil?
            return s.default
          else
            return s.convert( value )
          end
        end
      end

      def each_explicit_key
        return to_enum(:each_explicit_key) unless block_given?
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

    private

      attr :java_config

    end
  end
end

