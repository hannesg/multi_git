require 'bundler/setup'
Bundler.require

best_available = MultiGit::Backend.best
if best_available == MultiGit::JGitBackend
  puts "You can now use jgit!"
  puts 
  puts "To show you that it actually works, here is a list of files in main folder:"
  repo = MultiGit.open('../../')
  repo['HEAD^{tree}'].each do |file|
    puts file.name
  end
else
  puts "You are not using jgit. The best available backend is: #{best_available}"
  exit 1
end
