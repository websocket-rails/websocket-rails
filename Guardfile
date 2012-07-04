# A sample Guardfile
# More info at https://github.com/guard/guard#readme
notification :gntp
guard 'rspec', :version => 2 do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/websocket_rails/(.+)\.rb$})     { |m| "spec/unit/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end

guard 'coffeescript', :output => 'spec/javascripts/generated/assets' do
  watch(/^lib\/assets\/javascripts\/websocket_rails\/(.*).coffee/)
end

guard 'coffeescript', :output => 'spec/javascripts/generated/specs' do
  watch(/^spec\/javascripts\/websocket_rails\/(.*).coffee/)
end
