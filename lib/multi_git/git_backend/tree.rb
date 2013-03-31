require 'multi_git/tree'
require 'multi_git/git_backend/object'
module MultiGit::GitBackend
  class Tree < Object

    LS_TREE_REGEX = /^([0-7]{6}) (?:blob|tree|commit) (\h{40})\t(.+)$/

    include MultiGit::Tree

    def raw_entries
      @raw_entries ||= begin
        @git.call('ls-tree', oid) do |stdout|
          stdout.each_line.map do |line|
            raise unless LS_TREE_REGEX =~ line
            [$3,$1.to_i(8),$2]
          end
        end
      end
    end

  end
end
