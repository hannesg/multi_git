require 'multi_git/tree'
require 'multi_git/jgit_backend/object'
module MultiGit::JGitBackend

  class Tree

    EMPTY_BYTES = [].to_java :byte

    import 'org.eclipse.jgit.treewalk.CanonicalTreeParser'

    include MultiGit::Tree
    include MultiGit::JGitBackend::Object

    def each_entry
      repository.use_reader do |reader|
        it = CanonicalTreeParser.new(EMPTY_BYTES, reader, java_oid)
        until it.eof
          mode = it.getEntryRawMode
          type = MultiGit::Utils.type_from_mode mode
          yield it.getEntryPathString, mode, ObjectId.toString(it.getEntryObjectId), type
          it.next
        end
      end
    end


  end
end
