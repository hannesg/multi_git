module MultiGit

  module Walkable

    # @visibility private
    # @api private
    MODES = [:pre, :post, :leaves]

    # works like each, but recursive
    #
    # @param mode [:pre, :post, :leaves] 
    def walk( mode = :pre, &block )
      raise ArgumentError, "Unknown walk mode #{mode.inspect}. Use either :pre, :post or :leaves" unless MODES.include? mode
      return to_enum(:walk, mode) unless block
      case(mode)
      when :pre   then walk_pre(&block)
      when :post  then walk_post(&block)
      when :leaves then walk_leaves(&block)
      end
    end

  protected

    def walk_pre
      yield self
    end

    def walk_post
      yield self
    end

    def walk_leaves
      yield self
    end

  end
  
end
