source 'https://rubygems.org'

gemspec

jruby_without_cext = !defined?(ENV_JAVA) || ENV_JAVA['jruby.cext.enabled']=='true'
rugged_opts = []
unless jruby_without_cext
  if $debug
    warn "Skipping rugged on jruby, since your C extension support is disabled."
    warn "Pass -Xcext.enabled=true to JRuby or set JRUBY_OPTS or modify .jrubyrc to enable."
  end
  rugged_opts  << {:platform => 'ruby'}
end

gem 'rugged', '>= 0.17.0.b7', *rugged_opts
gem 'jbundler', :platform => 'jruby'
gem 'coveralls'
gem 'yard'

