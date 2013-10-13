require 'multi_git/object'
require 'forwardable'
require 'multi_git/jgit_backend/rewindeable_io'
class MultiGit::JGitBackend::Object

  import "org.eclipse.jgit.lib.ObjectId"

  extend Forwardable

  include MultiGit::Object

  def initialize(repository,oid, object = nil)
    @repository = repository
    @java_oid = oid
    @git = repository.__backend__
    @oid = ObjectId.toString(oid)
    @java_object = object
  end

  def bytesize
    java_object.getSize
  end

  def to_io
    MultiGit::JGitBackend::RewindeableIO.new( java_stream )
  end

  def content
    @content ||= to_io.read.freeze
  end

private

  def java_stream
    java_object.openStream
  end

protected

  attr :java_oid

  def java_object
    @java_object ||= repository.use_reader{|rdr| rdr.open(@java_oid) }
  end

end
