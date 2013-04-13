require 'multi_git/git_backend/object'
require 'multi_git/commit'
module MultiGit
  module GitBackend
    class Commit < Object
      include MultiGit::Commit

      def parents
        read!
        @parents ||= @parent_oids.map{|oid| repository.read(oid) }
      end

      def tree
        read!
        @tree ||= repository.read(@tree_oid)
      end

      def message
        read!
        @message
      end

      def read!
        return if @read
        @read = true
        @header, @message = content.split("\n\n")
        @parent_oids = []
        @header.each_line do |line|
          type, content = line.split(' ',2)
          case(type)
          when 'tree' then @tree_oid = content.chomp
          when 'parent' then @parent_oids << content.chomp
          when 'author' then @author = content
          when 'committer' then @committer = content
          else
            raise "Commit line type: #{type}"
          end
        end
      end

    end
  end
end

