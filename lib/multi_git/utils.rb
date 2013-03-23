module MultiGit
  module Utils

    # A
    def looks_bare?(path)
      return nil unless File.exists?(path)
      return !File.exists?(File.join(path,'.git')) &&
        File.exists?(File.join(path,'refs'))
    end

    extend self
  end
end
