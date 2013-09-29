require 'multi_git'
require 'logger'
describe "docs" do

  if defined?(JRUBY_VERSION) && (JRUBY_VERSION =~ /\A1.7.[45]/)
    pending "jruby 1.7.4 breaks yard"
    next
  end

  gem 'yard'
  require 'yard'

  YARD.parse('lib/**/*.rb')

  YARD::Registry.each do |object|
    if object.has_tag?('example')
      object.tags('example').each_with_index do |tag, i|
        code = tag.text.gsub(/^[^\n]*#UNDEFINED!/,'').gsub(/(.*)\s*#=> (.*)(\n|$)/){
          "expect(#{$1}).to #{$2}\n"
        }
        it "#{object.to_s} in #{object.file}:#{object.line} has a valid example #{(i+1).to_s}" do
          eval code
        end
      end
    end
  end

end
