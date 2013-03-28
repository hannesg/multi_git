module MultiGit::JGitBackend::Object

  import "org.eclipse.jgit.lib.ObjectId"

  def initialize(repository,oid, object = nil)
    @repository = repository
    @java_oid = oid
    @git = repository.__backend__
    @oid = ObjectId.toString(oid)
    @java_object = object
  end

protected

  attr :java_oid

  def java_object
    @java_object ||= repository.use_reader{|rdr| rdr.open(@java_oid) }
  end

end
