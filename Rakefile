
task "jbundle" do
  sh "jbundle"
end

task "prepare" do
  # nothing to do :)
end


if RUBY_ENGINE == 'jruby'
  task "prepare" => ['jbundle']
end

task "spec" => ['prepare'] do
  sh "rspec"
end

task "default" => "spec"
