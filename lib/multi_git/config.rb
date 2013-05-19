module MultiGit
  module Config

    DEFAULTS = {
      'core.logallrefupdates' => 'false'
    }

    include Enumerable

    def to_h
      Hash[to_a]
    end

  end
end
