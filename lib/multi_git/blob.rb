require 'stringio'
require 'multi_git/object'
require 'multi_git/builder'
module MultiGit
  module Blob

    module Base
      def type
        :blob
      end
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

      def content
        string
      end

      def content=(value)
        self.string = value.dup
      end

      def >>(repo)
        rewind
        return repo.write(read)
      end
    end

    include Object
    include Base

    def to_builder
      Builder.new(self)
    end

  end
end
