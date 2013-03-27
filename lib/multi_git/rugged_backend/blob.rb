require 'stringio'
require 'multi_git/blob'
require 'multi_git/rugged_backend/object'
module MultiGit::RuggedBackend
  class Blob < IO
    include MultiGit::Blob
    include MultiGit::RuggedBackend::Object

    delegate (IO.public_instance_methods-::Object.public_instance_methods) => 'to_io'
    delegate :size => :rugged_object

    def to_io
      @io ||= StringIO.new(content)
    end

  private
    def content
      @content ||= rugged_object.content.freeze
    end

  end
end
