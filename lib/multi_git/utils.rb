module MultiGit
  module Utils

    module AbstractMethods

      def abstract(name)
        class_eval <<RUBY
def #{name}(*args, &block)
  raise NotImplementedError, "Please implement #{name} for \#{self}"
end
RUBY
      end

    end

    # @visibility private
    # @api private
    module Memoizes

      class Strategy
        def memoized_variable( name )
          "@#{name}"
        end

        def unmemoized_method( name )
          "unmemoized_#{name}"
        end

        def memoized_setter_method( name )
          "set_memoized_#{name}"
        end

      end

      class Simple < Strategy
        def call( name )
return <<RUBY
alias #{unmemoized_method name} #{name}
def #{name}
  defined?(#{memoized_variable name}) ? #{memoized_variable name} : #{memoized_variable name} = #{unmemoized_method name}
end
def #{memoized_setter_method name}( value )
  #{memoized_variable name} = value
end
RUBY
        end
      end

      class Synced < Strategy
        def call( name )
return <<RUBY
alias #{unmemoized_method name} #{name}
def #{name}
  if defined?(#{memoized_variable name})
    return #{memoized_variable name}
  else
    #{sync} do
      if defined?(#{memoized_variable name})
        return #{memoized_variable name}
      else
        return #{memoized_variable name} = #{unmemoized_method name}
      end
    end
  end
end
def #{memoized_setter_method name}( value )
  #{memoized_variable name} = value
end
RUBY
        end

        def sync
          "synchronize"
        end
      end

      def memoize(*names)
        options = names.last.kind_of?(Hash) ? names.pop : {}
        strategy = options[:synchronize] ? Synced.new : Simple.new
        names.each do |name|
          class_eval strategy.call(name)
        end
      end
    end

    NULL_OID = '0'*40

    MODE_SYMLINK =     0120000
    MODE_SUBMODULE =   0160000
    MODE_DIRECTORY =   0040000
    MODE_FILE =        0100644
    MODE_EXECUTEABLE = 0100755

    MODE_TYPES = {
      MODE_SYMLINK     => :blob,
      MODE_SUBMODULE   => :commit,
      MODE_DIRECTORY   => :tree,
      MODE_FILE        => :blob,
      MODE_EXECUTEABLE => :blob
    }

    # @api private
    DOTS = { '.' => true, '..' => true }

    def empty_dir?(path)
      Dir.new(path).reject{|path| DOTS[path] }.none?
    end

    # A
    def looks_bare?(path)
      return nil unless ::File.exists?(path)
      return !::File.exists?(::File.join(path,'.git')) &&
        ::File.exists?(::File.join(path,'refs'))
    end

    # @api private
    def file_loadeable?(file)
      $LOAD_PATH.any?{|path| File.exists?( File.join(path, file) ) }
    end

    def type_from_mode(mode)
      MODE_TYPES.fetch(mode.to_i){ raise "Unknown file mode #{mode}" }
    end

    extend self
  end
end
