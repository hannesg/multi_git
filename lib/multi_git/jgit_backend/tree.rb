require 'multi_git/tree'
require 'multi_git/jgit_backend/object'
module MultiGit::JGitBackend

  class Tree

    EMPTY_BYTES = [].to_java :byte

    import 'org.eclipse.jgit.treewalk.CanonicalTreeParser'

    include MultiGit::Tree
    include MultiGit::JGitBackend::Object

    def raw_entries
      return @raw_entries if @raw_entries
      repository.use_reader do |reader|
        entries = []
        it = CanonicalTreeParser.new(EMPTY_BYTES, reader, java_oid)
        until it.eof
          mode = it.getEntryRawMode
          type = MultiGit::Utils.type_from_mode mode
          entries << [it.getEntryPathString, mode, ObjectId.toString(it.getEntryObjectId), type]
          it.next
        end
        @raw_entries = entries
      end
      return @raw_entries
    end
  end
end
