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
RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
class Something

  def initialize(matchers)
    @matchers = matchers
  end

  def ===(other)
    @matchers.all? do |k,v|
      o = other.send(k)
      v === o || v == o
    end
  end

  def inspect
    ['#<something ',@matchers.map{|k,v| k.to_s+'=>'+v.inspect}.join(' '),'>'].join
  end

  class << self
    alias [] new
  end

end

# A helper class which sorts the yielded args before checking them.
# This is usefull if the order
class YieldUnorderedArgs < RSpec::Matchers::BuiltIn::YieldSuccessiveArgs

private
  def args_match?
    return false if @expected.size != @actual.size

    @expected.zip(@actual.sort).all? do |expected, actual|
      expected === actual || actual == expected
    end
  end
end

module CustomMatchers

  def yield_unordered_args(*args)
    YieldUnorderedArgs.new(*args)
  end

end

RSpec.configure do |config|
  config.expect_with( :rspec, CustomMatchers )
end

require 'shared'

# Smart thing
# Tests are marked pending directly from code
old_verbose, $VERBOSE = $VERBOSE, nil
MultiGit::Error::NotYetImplemented = Class.new(RSpec::Core::Pending::PendingDeclaredInExample)
$VERBOSE = old_verbose
