require 'set'
require 'multi_git/tree'
require 'multi_git/builder'
require 'multi_git/file'
require 'multi_git/executeable'
require 'multi_git/symlink'
module MultiGit
  class Tree::Builder

    include MultiGit::Builder
    include Tree::Base

    # @return [Hash<String,MultiGit::TreeEntry::Base>]
    attr :dirty_entries
    private :dirty_entries

    # @return [MultiGit::Tree::Base, nil]
    attr :from

    def initialize(from = nil, &block)
      @dirty_entries = {}
      @from = from
      instance_eval(&block) if block
    end

    # @param [String] key
    # @return [TreeEntry::Builder, nil]
    def entry(key)
      if @from
        dirty_entries.fetch(key) do
          e = @from.entry(key)
          if e
            dirty_entries[key] = e.to_builder.with_parent(self)
          end
        end
      else
        dirty_entries[key]
      end
    end

    # @overload each(&block)
    #   @yield [entry]
    #   @yieldparam entry [MultiGit::TreeEntry]
    #
    # @overload each
    #   @return [Enumerable]
    def each
      return to_enum unless block_given?
      names.each do |name|
        yield entry(name)
      end
    end

    # TODO: cache
    def names
      names = @from ? @from.names.dup : []
      dirty_entries.each do |k,v|
        if v
          unless names.include? k
            names << k
          end
        else
          names.delete(k)
        end
      end
      return names
    end

    # @return [Hash<String,MultiGit::TreeEntry::Builder>]
    def entries
      Hash[names.map do |n| [n, entry(n)] end ]
    end

    def size
      names.size
    end

    def >>(repository)
      ent = []
      dirty_entries.each do |name, entry|
        if entry
          object = repository.write(entry)
          ent << [name, object.mode, object.oid]
        end
      end
      if @from
        @from.each do |entry|
          unless dirty_entries.key? entry.name
            ent << [entry.name, entry.mode, entry.oid]
          end
        end
      end
      return repository.make_tree(ent)
    end

    # @param (see Object#with_parent)
    # @return [Directory::Builder]
    def with_parent(parent, name)
      Directory::Builder.new(parent, name, self)
    end

    module DSL

      # @overload set(path, options = {:create => true }, &block)
      #   @param [String] path
      #   @param [Hash] options
      #   @yield [parent, name]
      #   @yieldparam parent [MultiGit::Tree, nil]
      #   @yieldparam name [String]
      #   @yieldreturn [#with_parent, nil]
      #
      # @overload set(path, options = {:create => true }, value)
      #   @param [String] path
      #   @param [Hash] options
      #   @param [#with_parent, nil] value
      #
      def set(key, *args, &block)
        options = {}
        case(args.size)
        when 0
          raise ArgumentError, "Expected a value or a block" unless block
          value = block
        when 1
          if block
            options = args[0]
            value = block
          else
            value = args[0]
          end
        when 2
          raise ArgumentError, "Expected either a value or a block, got both" if block
          options = args[0]
          value = args[1]
        else
          raise ArgumentError, "Expected 1-3 arguments, got #{args.size}"
        end
        # okay, a bit simple here for now
        parts = key.split('/').reject{|k| k == '' || k == '.' }
        if parts.any?{|p| p == ".." }
          raise MultiGit::Error::InvalidTraversal, "Traversal to parent directories is currently not supported while setting."
        end
        return traverse_set( self, parts, value, options.fetch(:create,true))
      end

      alias []= set

      # @api private
      def entry_set(key, value)
        dirty_entries[key] = make_entry(key, value)
      end

      def make_entry(key, value)
        if value.kind_of? Proc
          value = value.call(self, key)
        end
        if value.nil?
          return value
        elsif value.kind_of? String
          return MultiGit::File::Builder.new(self, key, value)
        elsif value.respond_to? :with_parent
          return value.with_parent(self, key)
        else
          raise ArgumentError, "No idea what to do with #{value.inspect}"
        end
      end
      private :make_entry

      def traverse_set(current, parts, value, create)
        if parts.none?
          raise
        end
        if parts.size == 1
          current.entry_set(parts[0], value)
          return current
        end
        part, *rest = parts
        if !current.respond_to? :entry
          raise MultiGit::Error::InvalidTraversal, "Can't traverse to #{path} from #{self.inspect}: #{current.inspect} doesn't contain an entry named #{part.inspect}"
        end
        entry = current.entry(part)
        if !entry.kind_of? MultiGit::Directory::Builder
          # fine
          if entry.kind_of? MultiGit::Tree
            entry = entry.to_builder
          elsif create == :overwrite || ( entry.nil? && create )
            entry = MultiGit::Directory::Builder.new(current, part)
          else
            if entry.nil?
              raise MultiGit::Error::InvalidTraversal, "#{current.inspect} doesn't contain an entry named #{part.inspect}"
            else
              raise MultiGit::Error::InvalidTraversal, "#{current.inspect} does contain an entry named #{part.inspect} but it's not a directory. To overwrite files specify create: :overwrite."
            end
          end
        end
        current.entry_set(part, traverse_set(entry, rest, value, create))
        return current
      end
      private :traverse_set

      def file(name, content = nil, &block)
        set(name){|parent, name|
          File::Builder.new(parent, name, content, &block)
        }
      end

      def executeable(name, content = nil, &block)
        set(name){|parent, name|
          Executeable::Builder.new(parent, name, content, &block)
        }
      end

      def directory(name, &block)
        set(name){|parent, name|
          Directory::Builder.new(parent, name, &block)
        }
      end

      def link(name, target)
        set(name){|parent, name|
          Symlink::Builder.new(parent, name, target)
        }
      end

      def delete(name)
        set(name){ nil }
      end

      # @return [self]
      def to_builder
        self
      end

      # Checks if the file at the given path was changed.
      #
      # @param [String] path
      #
      # @example from scratch
      #   builder = MultiGit::Tree::Builder.new
      #   builder.file('a_file','some content')
      #   builder.changed? 'a_file' #=> eq true
      #   builder.changed? 'another_file' #=> eq false
      #   builder.changed? #=> eq true
      def changed?( path = '.' )
        begin
          new = traverse(path)
        rescue Error::EntryDoesNotExist
          return false unless from
          begin
            old = from.traverse(path)
          rescue Error::EntryDoesNotExist
            return false
          end
          return true
        end
        return true unless from
        begin
          old = from.traverse(path)
        rescue Error::EntryDoesNotExist
          return true
        end
        return new != old
      end

    end

    include DSL

  end
end
require 'multi_git/directory'
