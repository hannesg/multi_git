require 'forwardable'
module MultiGit; module Config

  class Schema

    attr :default

    def initialize(default = nil)
      @default = default
    end

    def list?
      false
    end

    def convert( plain_value )
      plain_value
    end

    def unconvert( complex_value )
      complex_value.to_s
    end

    NULL = self.new

    class String < self
    end

    class Integer < self
      def convert( plain_value )
        plain_value.to_i
      end
    end

    class Array < self
      def list?
        true
      end
      def unconvert( complex_value )
        complex_value.map(&:to_s)
      end
    end

    class Boolean < self
      CONVERSIONS = {
        'true'  => true,
        'yes'   => true,
        '1'     => true,
        'false' => false,
        'no'    => false,
        '0'     => false
      }
      CONVERSIONS.default = true
      def convert( plain_value )
        CONVERSIONS[plain_value]
      end
    end

    class Root

      def initialize(hash = Hash.new(Hash.new(Hash.new(NULL))) )
        @hash = hash
      end

      def schema
        @hash
      end

      def section(key, &block)
        sec = Section.new(@hash.fetch(key){ @hash[key] = Hash.new(Hash.new(NULL))})
        sec.instance_eval(&block) if block_given?
        return sec
      end

    end

    class Section

      extend Forwardable

      def initialize(hash)
        @hash = hash
      end

      def section(key, &block)
        sec = Subsection.new(@hash.fetch(key){ @hash[key] = Hash.new(NULL)})
        sec.instance_eval(&block) if block_given?
        return sec
      end

      def nil_section
        section(nil)
      end

      def any_section(&block)
        sec = Subsection.new(@hash.default)
        sec.instance_eval(&block) if block_given?
        return sec
      end

      delegate [:integer, :string, :array, :bool] => :nil_section

      alias int integer

    end

    class Subsection

      def initialize(hash)
        @hash = hash
      end

      def integer(name, default = nil)
        @hash[name] = Integer.new(default)
      end

      def string(name, default = nil)
        @hash[name] = String.new(default)
      end

      def array(name, default = nil)
        @hash[name] = Array.new(default)
      end

      def bool(name, default = nil)
        @hash[name] = Boolean.new(default)
      end

      alias int integer

    end

    def self.build(&block)
      ro = Root.new
      ro.instance_eval(&block)
      return ro.schema
    end

  end

end; end
