module MultiGit
  class Handle < Struct.new(:name, :email)

    EMAIL = /\A\w+@\w+\.\w+\z/ # close enough, but
    NAME_WITH_EMAIL = /\A(.*) <(\w+@\w+\.\w+)>\z/

    def self.parse(string)
      case(string)
      when EMAIL then return new(string, string)
      when NAME_WITH_EMAIL then return new($1,$2)
      else raise ArgumentError, "Unknown handle format: #{string}. Please use either 'user@example.com' or 'User <user@example.com>'"
      end
    end

  end
end
