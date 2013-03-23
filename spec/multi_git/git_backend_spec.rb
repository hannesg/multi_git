describe MultiGit::GitBackend, :if => MultiGit::GitBackend.available? do

  it_behaves_like "a MultiGit backend"

end
