require 'bundler/setup'
require 'simplecov'
require 'coveralls'

SimpleCov.start do
  formatter SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
  add_filter "/spec"
  maximum_coverage_drop 5
end

Bundler.require(:default, :development)

require 'shared'

# Smart thing
# Tests are marked pending directly from code
old_verbose, $VERBOSE = $VERBOSE, nil
MultiGit::Error::NotYetImplemented = Class.new(RSpec::Core::Pending::PendingDeclaredInExample)
$VERBOSE = old_verbose
