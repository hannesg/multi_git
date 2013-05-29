require 'multi_git/config/schema'
module MultiGit
  module Config

    DEFAULT_SCHEMA = \
Schema.build do

section 'core' do
  bool 'bare', false
  bool 'filemode', true
  bool 'logallrefupdates', false
  int 'repositoryformatversion', 0
end

section 'remote' do
  any_section do
    array 'url'
    string 'fetch'
  end
end

end

  end
end
