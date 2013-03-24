require 'multi_git/blob'
module MultiGit::JGitBackend
  class Blob < IO

    include MultiGit::Blob

    def oid
      Java::OrgEclipseJgitLib::ObjectId.toString(@oid)
    end

  end
end
