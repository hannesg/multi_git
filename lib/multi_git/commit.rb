require 'multi_git/utils'
require 'multi_git/handle'
require 'multi_git/builder'
module MultiGit

  module Commit

    module Base
      extend Utils::AbstractMethods

      # @return String
      abstract :message

      # @return Tree
      abstract :tree

      # @return [Array<Commit>]
      abstract :parents

      # @return [Time]
      abstract :time
      # @return [Handle]
      abstract :author

      # @return [Time]
      abstract :commit_time
      # @return [Handle]
      abstract :committer

      def type
        :commit
      end
    end

    # A commit builder helps creating new commits by 
    # providing a simple interface, sane defaults and some
    # validations.
    #
    # You can create a new commit using the commit builder like this:
    # 
    # @example Commit an small tree
    #   #setup:
    #   dir = `mktemp -d`
    #   # example:
    #   builder = MultiGit::Commit::Builder.new
    #   builder.message = "My first commit"
    #   builder.by "me@example.com"
    #   builder.tree["a_file"] = "some content"
    #   # builder is now ready to be inserted
    #   repository = MultiGit.open(dir, init: true)
    #   commit = repository << builder #=> be_a MultiGit::Commit
    #   commit.tree['a_file'].content  #=> eql "some content"
    #   # teardown:
    #   `rm -rf #{dir}`
    class Builder
      include MultiGit::Builder
      include Base

      # @return (see MultiGit::Commit::Base#message)
      def message(*args)
        if args.any?
          self.message = args.first
          return self
        else
          return @message
        end
      end

      #
      # @yield allows 
      # @return [Tree::Builder]
      def tree(&block)
        @tree.instance_eval(&block) if block
        @tree
      end
      # @return [Array<Commit::Base>]
      attr :parents

      # @return (see MultiGit::Commit::Base#time)
      attr :time
      # @return (see MultiGit::Commit::Base#commit_time)
      attr :commit_time

      # @return (see MultiGit::Commit::Base#author)
      attr :author
      # @return (see MultiGit::Commit::Base#committer)
      attr :committer

      attr_writer :author, :committer
      attr_writer :message

      # @param time [Time]
      def time=(time)
        raise ArgumentError, "Expected a Time, got #{time.inspect}" unless time.kind_of? Time
        @time = time
      end

      # @param time [Time]
      def commit_time=(time)
        raise ArgumentError, "Expected a Time, got #{time.inspect}" unless time.kind_of? Time
        @commit_time = time
      end

      # @param handle [Handle, String]
      def committer=(handle)
        @committer = parse_handle(handle)
      end

      # @param handle [Handle, String]
      def author=(handle)
        @author = parse_handle(handle)
      end

      # DSL method to set author and committer in one step
      # @param handle [Handle, String]
      # @return self
      def by(handle)
        self.author = self.committer = handle
        return self
      end

      def at(time)
        self.time = self.commit_time = time
        return self
      end

      def initialize(from = nil, &block)
        @parents = []
        if from.kind_of? Tree
          @tree = from.to_builder
        elsif from.kind_of? Tree::Builder
          @tree = from
        elsif from.kind_of? Commit
          @tree = from.tree.to_builder
          @parents << from
        elsif from.nil?
          @tree = Tree::Builder.new
        end
        @author = nil
        @committer = nil
        @time = @commit_time = Time.now
        instance_eval(&block) if block
      end

      def >>(repo)
        new_tree = repo << tree
        new_parents = parents.map{|p| repo.write(p).oid }
        return repo.make_commit(
          :time => time,
          :author => author,
          :commit_time => commit_time,
          :committer => committer,
          :parents => new_parents,
          :tree => new_tree.oid,
          :message => message,
          :update_ref => []
        )
      end

    protected

      def parse_handle(handle)
        case(handle)
        when Handle then
          return handle
        when String then
          return Handle.parse(handle)
        else
          raise ArgumentError, "Expected a String or a Handle, got #{handle.inspect}"
        end
      end

    end

    include Base

  end
end

