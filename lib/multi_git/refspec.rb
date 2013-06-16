module MultiGit

  # A RefSpec describes which and how references are updated during 
  # push and pull.
  #
  # It basically says: set the "to" ref to the target of "from"
  #
  # @example
  #   refspecs = MultiGit::RefSpec.parse('master')
  #
  class RefSpec < Struct.new(:from,:to,:forced)

    extend Utils::AbstractMethods

    # @!attribute from
    #   @return [String]

    # @!attribute to
    #   @return [String]

    # @!attribute forced
    #   @return [Boolean]

    alias forced? forced

    # @param from [String]
    # @param to [String]
    # @param forced [Boolean]
    def initialize(from,to,forced = false)
      super
    end

    def inspect
      ['#<',self.class,' ',forced ? '+':'',from,':',to,'>'].join
    end

    def to_s
      [forced ? '+':'',from,':',to].join
    end

    class Parser

      REF = %r{\A(\+?)([a-zA-Z/0-9_*]+)?(?:(:)([a-zA-Z/0-9_*]+)?)?\z}

      attr :from_base, :to_base

      def initialize(from_base = 'refs/heads/', to_base )
        @from_base = from_base
        @to_base = to_base
      end

      # 
      # @param args [RefSpec, String, Hash, Range, ...]
      # @return [Array<RefSpec>]
      def [](*args)
        args.collect_concat do |arg|
          if arg.kind_of? RefSpec
            [arg]
          elsif arg.kind_of? String
            [parse_string(arg)]
          elsif arg.kind_of? Hash
            arg.map{|k,v| parse_pair(k,v) }
          elsif arg.kind_of? Range
            [parse_pair(arg.begin, arg.end)]
          else
            raise ArgumentError, "Expected a String, Hash or Range. Got #{arg.inspect}"
          end
        end
      end

    private
      def parse_string(string)
        if ma = REF.match(string)
          if ma[2]
            from = normalize(from_base, ma[2])
          end
          if ma[3]
            to  = normalize(to_base, ma[4])
          else
            to  = normalize(to_base, ma[2])
          end
          RefSpec.new( from, to, ma[1] == '+' )
        end
      end

      def parse_pair(a,b)
        RefSpec.new( normalize(from_base,a.to_s), normalize(to_base,b.to_s) )
      end

      def normalize(base, name)
        ns = name.split(SLASH, -1)
        bs = base.split(SLASH, -1)
        fill_reverse(bs, ns)
        return bs.join(SLASH)
      end

      def fill_reverse(a,b)
        s = a.size - b.size
        b.each_with_index do |e, i|
          a[s+i] = e
        end
      end

    end

    DEFAULT_PARSER = Parser.new('refs/remotes/origin/')

    class << self

      def parse(arg)
        DEFAULT_PARSER[arg].first
      end

    end

  end

end
