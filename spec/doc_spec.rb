require 'multi_git'
describe "docs" do

  gem 'yard'
  require 'yard'

  YARD.parse('lib/**/*.rb').inspect

  YARD::Registry.each do |object|
    if object.has_tag?('example')
      object.tags('example').each_with_index do |tag, i|
        code = tag.text.gsub(/^[^\n]*#UNDEFINED!/,'').gsub(/(.*)\s*#=> (.*)(\n|$)/){
          "expect(#{$1}).to #{$2}\n"
        }
        it "#{object.to_s} in #{object.file}:#{object.line} should have valid example #{(i+1).to_s}" do
          eval code
        end
      end
    end
  end

end
