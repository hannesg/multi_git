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

      def committer
        read!
        @committer
      end

      def author
        read!
        @author
      end

      def time
        read!
        @time
      end

      def commit_time
        read!
        @commit_time
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
          when 'author' then
            @author, @time = parse_signature(content)
          when 'committer' then
            @committer, @commit_time = parse_signature(content)
          else
            raise "Commit line type: #{type}"
          end
        end
      end

    private

      SIGNATURE_RX = /\A(.+) <([^>]+)> (\d+) ([\-+]\d{2})(\d{2})\Z/

      def parse_signature(content)
        match = SIGNATURE_RX.match(content)
        return MultiGit::Handle.new(match[1],match[2]), Time.at(match[3].to_i).localtime(match[4]+':'+match[5])
      end

    end
  end
end

