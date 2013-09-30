require 'multi_git/object'
require 'multi_git/walkable'
require 'forwardable'
module MultiGit
  module Tree

    # @visibility protected
    SLASH = '/'.freeze

    module Base

      include Enumerable
      include Walkable

      def type
        :tree
      end

      def parent?
        false
      end

      def key?(key)
        if key.kind_of? String
          return entries.key?(key)
        else
          raise ArgumentError, "Expected a String, got #{key.inspect}"
        end
      end

      # @param [String] key
      # @return [MultiGit::TreeEntry, nil]
      def entry(key)
        entries[key]
      end

      # Traverses to path
      # @param [String] path
      # @param [Hash] options
      # @option options [Boolean] :follow follow sylinks ( default: true )
      # @raise [MultiGit::Error::InvalidTraversal] if the path is not reacheable
      # @raise [MultiGit::Error::CyclicSymlink] if a cyclic symlink is found
      # @return [MultiGit::TreeEntry]
      def traverse(path, options = {})
        unless path.kind_of? String
          raise ArgumentError, "Expected a String, got #{path.inspect}"
        end
        parts = path.split('/').reverse!
        current = self
        follow = options.fetch(:follow){true}
        symlinks = Set.new
        while parts.any?
          part = parts.pop
          if part == '..'
            unless current.parent?
              raise MultiGit::Error::InvalidTraversal, "Can't traverse to parent of #{current.inspect} since I don't know where it is."
            end
            current = current.parent
          elsif part == '.' || part == ''
            # do nothing
          else
            if !current.respond_to? :entry
              raise MultiGit::Error::NotADirectory, "Can't traverse to #{path} from #{self.inspect}: #{current.inspect} doesn't contain an entry named #{part.inspect}"
            end
            entry = current.entry(part)
            raise MultiGit::Error::EntryDoesNotExist, "Can't traverse to #{path} from #{self.inspect}: #{current.inspect} doesn't contain an entry named #{part.inspect}" unless entry
            # may be a symlink
            if entry.respond_to? :target
              # this is a symlink
              if symlinks.include? entry
                # We have already seen this symlink
                #TODO: it's okay to see a symlink twice if requested
                raise MultiGit::Error::CyclicSymlink, "Cyclic symlink detected while traversing #{path} from #{self.inspect}."
              else
                symlinks << entry
              end
              if follow
                parts.push(*entry.target.split(SLASH))
              else
                if parts.none?
                  return entry
                else
                  raise ArgumentError, "Can't follow symlink #{entry.inspect} since you didn't allow me to"
                end
              end
            else
              current = entry
            end
          end
        end
        return current
      end

      alias / traverse
      alias [] traverse

      # Works like the builtin Dir.glob
      #
      # @param pattern [String] A glob pattern
      # @param flags [Integer] glob flags
      # @yield [MultiGit::TreeEntry]
      # @return [Enumerator] if called without a block
      # @return self if called with a block
      #
      # @example
      #   bld = MultiGit::Tree::Builder.new do
      #     file "file"
      #     directory "folder" do
      #       file "file"
      #     end
      #   end
      #   bld.glob( '**/file' ).map(&:path) #=> eq ['file','folder/file']
      #
      # @see http://ruby-doc.org/core/Dir.html#method-c-glob
      def glob( pattern, flags = 0 )
        return to_enum(:glob, pattern, flags) unless block_given?
        l = respond_to?(:path) ? path.size : 0
        flags |= ::File::FNM_PATHNAME
        if ::File.fnmatch(pattern, '.', flags)
          yield self
        end
        each do |entry|
          entry.walk_pre do |sub_entry|
            if ::File.fnmatch(pattern, sub_entry.path[l..-1], flags)
              yield sub_entry
              false
            end
          end
        end
        return self
      end

      # @yield [MultiGit::TreeEntry]
      def each
        return to_enum unless block_given?
        entries.each do |name, entry|
          yield entry
        end
        return self
      end

      # @visibility private
      def walk_pre(&block)
        each do |child|
          child.walk(:pre, &block)
        end
      end

      # @visibility private
      def walk_post(&block)
        each do |child|
          child.walk(:post, &block)
        end
      end

      # @visibility private
      def walk_leaves(&block)
        each do |child|
          child.walk(:leaves,&block)
        end
      end

      # @return [Integer] number of entries
      def size
        entries.size
      end

      # @return [Array<String>] names of all entries
      def names
        entries.keys
      end

      def ==( other )
        return false unless other.respond_to? :entries
        entries == other.entries
      end

      alias eql? ==

      def hash
        entries.hash
      end

    end

    include Base
    include Object

    def to_builder
      Builder.new(self)
    end

    # @visibility private
    def inspect
      ['#<',self.class.name,' ',oid,' repository:', repository.inspect,'>'].join
    end

    # @return [Hash<String, MultiGit::TreeEntry>]
    def entries
      @entries ||= Hash[ raw_entries.map{|name, mode, oid| [name, make_entry(name, mode, oid) ] } ]
    end

  protected
    def raw_entries
      raise Error::NotYetImplemented, "#{self.class}#each_entry"
    end

    def make_entry(name, mode, oid)
      repository.read_entry(self, name,mode,oid)
    end

  end
end
require 'multi_git/tree/builder'
