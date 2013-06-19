require 'multi_git/tree'
require 'multi_git/rugged_backend/object'
module MultiGit::RuggedBackend
  class Tree < Object
    include MultiGit::Tree
    extend MultiGit::Utils::Memoizes

    def size
      rugged_object.count
    end

    def raw_entries
      rugged_object.map do |entry|
        [entry[:name], entry[:filemode], entry[:oid]]
      end
    end

    memoize :raw_entries

  end
end
