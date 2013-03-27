module MultiGit::GitBackend::Object

  def initialize(repository, oid, content = nil)
    @repository = repository
    @git = repository.__backend__
    @oid = oid
    @content = content ? content.dup.freeze : nil
  end

end
