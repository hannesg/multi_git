describe MultiGit::GitBackend, :git => true, :if => MultiGit::GitBackend.available? do

  it_behaves_like "a MultiGit backend"

end
