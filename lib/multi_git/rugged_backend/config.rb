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
        if v.size == 0
          s.default
        elsif s.list?
          s.convert(v)
        else
          s.convert(v.last)
        end
      end

      def set(section, subsection, key, value)
        qk = qualified_key(section, subsection, key)
        if value.kind_of? Array
          raise Error::NotYetImplemented, "Rugged lacks support for writing array values to config"
        end
        @rugged_config.delete(qk)
        @config[ [section, subsection, key] ] = Array(value).map(&:to_s)
        Array(value).each do |v|
          @rugged_config[qk]=v
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
