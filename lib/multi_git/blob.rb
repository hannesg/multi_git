require 'stringio'
require 'multi_git/object'
require 'multi_git/builder'
require 'digest/sha1'
module MultiGit
  module Blob

    module Base
      def type
        :blob
      end

      # @visibility private
      def ==(other)
        return false unless other.respond_to? :oid
        return oid == other.oid
      end

      # @visibility private
      def inspect
        ['<',self.class,' ',oid,'>'].join
      end

      # @visibility private
      alias to_s inspect
    end

    class Builder < StringIO
      include Base
      include MultiGit::Builder

      def initialize(content = nil)
        super()
        if content.kind_of? Blob
          self << content.content
        elsif content.kind_of? String
          self << content
        elsif content.kind_of? IO
          IO.copy_stream(content, self)
        elsif content
          raise ArgumentError
        end
      end

      alias content string

      def content=(value)
        self.string = value.dup
      end

      def >>(repo)
        rewind
        return repo.write(read)
      end

      def oid
        dig = Digest::SHA1.new
        dig << "blob #{size}\0"
        dig << content
        return dig.hexdigest
      end

      # Turns the blob into a file using the given parent and filename.
      # @param [Object] parent
      # @param [String] name
      # @return [File::Builder]
      def with_parent(parent, name)
        File::Builder.new(parent, name, self)
      end
    end

    include Object
    include Base

    # @return [Builder]
    def to_builder
      Builder.new(self)
    end

    # Turns the blob into a file using the given parent and filename.
    # @param [Object] parent
    # @param [String] name
    # @return [File]
    def with_parent(parent, name)
      File.new(parent, name, self)
    end

  end
end
require 'multi_git/file'
