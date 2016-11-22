require 'multi_git/object'
require 'forwardable'
class MultiGit::GitBackend::Object

  extend Forwardable

  include MultiGit::Object

  attr :extra_data

  def initialize(repository, oid, content = nil)
    @repository = repository
    @git = repository.__backend__
    @oid = oid
    @content = content ? content.dup.freeze : nil
    @extra_data = {}
  end

  def bytesize
    @size ||= begin
      if @content
        @content.bytesize
      else
        @git['cat-file',:s,@oid].to_i
      end
    end
  end

  def content
    @content ||= @git['cat-file',type.to_s,@oid].freeze
  end

  def to_io
    StringIO.new(content)
  end

end
