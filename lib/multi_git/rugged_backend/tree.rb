require 'multi_git/tree'
require 'multi_git/rugged_backend/object'
module MultiGit::RuggedBackend
  class Tree
    include MultiGit::Tree
    include MultiGit::RuggedBackend::Object

    def size
      rugged_object.count
    end

    def raw_entries
      @raw_entries ||= rugged_object.map do |entry|
        [entry[:name], entry[:filemode], entry[:oid]]
      end
    end

  end
end
