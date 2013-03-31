require 'multi_git/object'
require 'forwardable'
class MultiGit::JGitBackend::Object < IO

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

  delegate (IO.public_instance_methods-::Object.public_instance_methods) => 'to_io'

  def size
    java_object.getSize
  end

  def rewind
    java_stream.reset
  end

  def to_io
    @io ||= java_stream.to_io
  end

private

  def java_stream
    @java_stream ||= begin
                       stream = java_object.openStream
                       stream.mark(size)
                       stream
                     end
  end

protected

  attr :java_oid

  def java_object
    @java_object ||= repository.use_reader{|rdr| rdr.open(@java_oid) }
  end

end
