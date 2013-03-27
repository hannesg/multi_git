require 'multi_git/object'
module MultiGit::RuggedBackend::Object

  def initialize( repository, oid, object = nil )
    @repository = repository
    @git = repository.__backend__
    @oid = oid
    @rugged_object = object
  end

protected

  def rugged_object
    @rugged_object ||= @git.lookup(@oid)
  end

end
