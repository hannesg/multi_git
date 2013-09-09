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

    attr :entries
    attr :from

    def initialize(from = nil, &block)
      @entries = {}
      @from = from
      instance_eval(&block) if block
    end

    def entry(key)
      if @from
        @entries.fetch(key) do
          e = @from.entry(key)
          if e
            @entries[key] = e.to_builder.with_parent(self)
          end
        end
      else
        @entries[key]
      end
    end

    def each
      return to_enum unless block_given?
      names.each do |name|
        yield entry(name)
      end
    end

    # TODO: cache
    def names
      names = @from ? @from.names.dup : []
      @entries.each do |k,v|
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

    def size
      names.size
    end

    def >>(repository)
      ent = []
      @entries.each do |name, entry|
        if entry
          object = repository.write(entry)
          ent << [name, object.mode, object.oid]
        end
      end
      if @from
        @from.each do |entry|
          unless @entries.key? entry.name
            ent << [entry.name, entry.mode, entry.oid]
          end
        end
      end
      return repository.make_tree(ent)
    end

    module DSL

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

      def entry_set(key, value)
        entries[key] = make_entry(key, value)
      end

      def make_entry(key, value)
        if value.kind_of? Proc
          value = value.call(self, key)
        end
        if value.nil?
          return value
        elsif value.kind_of? String
          return MultiGit::File::Builder.new(self, key, value)
        elsif value.kind_of? MultiGit::Builder
          return value.with_parent(self)
        else
          raise ArgumentError, "No idea what to do with #{value.inspect}"
        end
      end

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
      def changed?( path )
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
