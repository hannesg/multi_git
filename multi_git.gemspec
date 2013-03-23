Gem::Specification.new do |gem|
  gem.name    = 'multi_git'
  gem.version = '0.0.1.alpha1'
  gem.date    = Time.now.strftime("%Y-%m-%d")

  gem.summary = "Use all the gits"

  gem.authors  = ['Hannes Georg']
  gem.email    = 'hannes.georg@googlemail.com'
  gem.homepage = 'https://github.com/hannesg/ridley-git'

  # ensure the gem is built out of versioned files
  gem.files = Dir['lib/**/*'] & `git ls-files -z`.split("\0")

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "simplecov"
end
