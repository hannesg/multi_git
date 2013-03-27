require 'multi_git/tree'
require 'multi_git/rugged_backend/object'
module MultiGit::RuggedBackend
  class Tree
    include MultiGit::Tree
    include MultiGit::RuggedBackend::Object

    def size
      rugged_object.count
    end

    def each_entry
      return to_enum(:each_entry) unless block_given?
      rugged_object.each do |entry|
        yield entry[:name], entry[:mode], entry[:oid], entry[:type]
      end
    end

  end
end
