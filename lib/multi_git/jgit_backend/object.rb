require 'multi_git/object'
require 'forwardable'
require 'multi_git/jgit_backend/rewindeable_io'
class MultiGit::JGitBackend::Object

  import "org.eclipse.jgit.lib.ObjectId"

  extend Forwardable
  extend MultiGit::Utils::Memoizes

  include MultiGit::Object

  def initialize(repository,oid, object = nil)
    @repository = repository
    @java_oid = oid
    @git = repository.__backend__
    @oid = ObjectId.toString(oid)
    set_memoized_java_object( object ) if object
  end

  def bytesize
    java_object.getSize
  end

  def to_io
    MultiGit::JGitBackend::RewindeableIO.new( java_stream )
  end

  def content
    to_io.read.freeze
  end

  memoize :content

private

  def java_stream
    stream = java_object.openStream
    stream.mark(bytesize)
    stream
  end

protected

  attr :java_oid

  def java_object
    repository.use_reader{|rdr| rdr.open(@java_oid) }
  end

  memoize :java_object

end
