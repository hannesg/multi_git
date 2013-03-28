module MultiGit
  module Utils

    MODE_TREE =        0040000
    MODE_FILE =        0100644
    MODE_EXECUTEABLE = 0100755

    MODE_TYPES = {
      MODE_TREE =>        :tree,
      MODE_FILE =>        :blob,
      MODE_EXECUTEABLE => :blob
    }

    # A
    def looks_bare?(path)
      return nil unless File.exists?(path)
      return !File.exists?(File.join(path,'.git')) &&
        File.exists?(File.join(path,'refs'))
    end

    def type_from_mode(mode)
      MODE_TYPES.fetch(mode.to_i){ raise "Unknown file mode #{mode}" }
    end

    extend self
  end
end
