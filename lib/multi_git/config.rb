require 'multi_git/utils'
require 'multi_git/config/default_schema'
module MultiGit
  module Config

    extend Utils::AbstractMethods
    include Enumerable

    def schema
      DEFAULT_SCHEMA
    end

    def schema_for( section, subsection, key )
      schema[section][subsection][key]
    end

    def default?( section, subsection, key )
      get(section, subsection, key) == schema_for(section, subsection, key).default
    end

    # @overload []( section, subsection = nil, key )
    #  @param section [String]
    #  @param subsection [String, nil]
    #  @param key [String]
    #  @return value
    #
    # @overload []( qualified_key )
    #  @param qualified_key [String] the fully-qualified key, seperated by dots
    #  @return value
    #
    def []( *args )
      case( args.size )
      when 3 then get( *args )
      when 2 then get( args[0], nil, args[1] )
      when 1 then
        get( *split_key(args[0]) )
      else
        raise ArgumentError, 
         "wrong number of arguments (#{args.size} for 1..3)"
      end
    end

    # @!method get( section, subsection, key)
    #   @api private
    abstract :get


    # @!method each_explicit_key
    #   @yield [section, subsection, key]
    abstract :each_explicit_key

    DOT = '.'

    def qualified_key( section, subsection = nil, key )
      [section, DOT, subsection, subsection ? DOT : nil, key].join
    end

    def split_key( qualified_key )
      split = qualified_key.split('.')
      case(split.size)
      when 2 then [ split[0], nil, split[1] ]
      when 3 then split
      else
        raise ArgumentError, "Expected the qualified key to be formatted as 'section[.subsection].key' got #{qualified_key}"
      end
    end

    # Expensive. Use only for debug
    def each
      return to_enum unless block_given?
      each_explicit_key do |*key|
        next if default?(*key)
        yield key, get(*key)
      end
    end

    # Expensive. Use only for debug.
    def to_h
      Hash[each.to_a]
    end

    def inspect
      ['{config', *each.map{|key, value| " "+qualified_key(*key)+" => "+value.inspect },'}'].join("\n")
    end

  end
end
