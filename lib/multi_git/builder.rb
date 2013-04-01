# A builder knows by itself how it is persistet
module MultiGit::Builder

  def >>(repo)
    raise 
  end

  def to_builder
    self
  end

end
