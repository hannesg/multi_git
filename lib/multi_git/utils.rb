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
