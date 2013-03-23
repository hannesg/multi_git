module MultiGit

  module Error

    class NotARepository < ArgumentError
      include Error
    end

  end

end
