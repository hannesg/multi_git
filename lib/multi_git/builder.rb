require 'multi_git/utils'
# Builders provides simple interfaces to create complex structures like trees and commits.
module MultiGit::Builder

  extend MultiGit::Utils::AbstractMethods

  # @!method >>(repository)
  #   @abstract
  #   Writes the content of this builder to the given repository.
  #   @param [Repository] repository
  #   @return [MultiGit::Object] the persisted object
  abstract :>>

  # @return [self] self
  def to_builder
    self
  end

end
