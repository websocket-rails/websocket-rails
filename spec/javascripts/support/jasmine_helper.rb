#Use this file to set/override Jasmine configuration options
#You can remove it if you don't need it.
#This file is loaded *after* jasmine.yml is interpreted.
#
#Example: using a different boot file.
#Jasmine.configure do |config|
#   config.boot_dir = '/absolute/path/to/boot_dir'
#   config.boot_files = lambda { ['/absolute/path/to/boot_dir/file.js'] }
#end
#
require 'coffee-script'

puts "Precompiling assets..."

root = File.expand_path("../../../../lib/assets/javascripts/websocket_rails", __FILE__)
destination_dir = File.expand_path("../../../../spec/javascripts/generated/assets", __FILE__)

glob = File.expand_path("**/*.js.coffee", root)

Dir.glob(glob).each do |srcfile|
  srcfile = Pathname.new(srcfile)
  destfile = srcfile.sub(root, destination_dir).sub(".coffee", "")
  FileUtils.mkdir_p(destfile.dirname)
  File.open(destfile, "w") {|f| f.write(CoffeeScript.compile(File.new(srcfile)))}
end
puts "Compiling jasmine coffee scripts into javascript..."
root = File.expand_path("../../../../spec/javascripts/websocket_rails", __FILE__)
destination_dir = File.expand_path("../../generated/specs", __FILE__)

glob = File.expand_path("**/*.coffee", root)

Dir.glob(glob).each do |srcfile|
  srcfile = Pathname.new(srcfile)
  destfile = srcfile.sub(root, destination_dir).sub(".coffee", ".js")
  FileUtils.mkdir_p(destfile.dirname)
  File.open(destfile, "w") {|f| f.write(CoffeeScript.compile(File.new(srcfile)))}
end

