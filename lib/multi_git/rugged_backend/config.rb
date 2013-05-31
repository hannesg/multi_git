require 'forwardable'
require 'multi_git/config'
module MultiGit
  module RuggedBackend
    class Config

      include MultiGit::Config

      def initialize(rugged_config)
        @rugged_config = rugged_config
        @config = Hash.new([])
        rugged_config.each_pair do |qk, value|
          key = split_key(qk)
          @config.fetch(key){ @config[key] = [] } << value
        end
      end

      def get(section, subsection, key)
        s = schema_for(section, subsection, key)
        v = @config[ [section, subsection,key] ]
        if s.list?
          s.convert(v)
        elsif v.size == 1
          s.convert(v[0])
        elsif v.size == 0
          s.default
        else
          raise Error::DuplicateConfigKey, qualified_key(section, subsection, key)
        end
      end

      def each_explicit_key
        return to_enum(:each_explicit_key) unless block_given?
        @config.each_key do |k|
          yield *k
        end
      end

    private

      attr :rugged_config

    end
  end
end
