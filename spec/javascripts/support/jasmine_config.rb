# spec/javascripts/support/jasmine_config.rb
# when jasmine starts the server out-of-process, it needs this in order to be able to invoke the asset tasks
unless Object.const_defined?(:Rake)
  require 'rake'
  load File.expand_path('../../../../Rakefile', __FILE__)
end

require 'coffee_script'

module Jasmine
  class Config
    include Rake::DSL

    def js_files(spec_filter = nil)
      # remove all generated files
      generated_files_directory = File.expand_path("../../../../spec/javascripts/generated/assets", __FILE__)
      rm_rf generated_files_directory, :secure => true

      precompile_app_assets
      compile_jasmine_javascripts

      # this is code from the original jasmine config js_files method - you could also just alias_method_chain it
      spec_files_to_include = spec_filter.nil? ? spec_files : match_files(spec_dir, [spec_filter])
      src_files.collect {|f| "/" + f } + helpers.collect {|f| File.join(spec_path, f) } + spec_files_to_include.collect {|f| File.join(spec_path, f) }
    end

    private

    # this method compiles all the same javascript files your app will
    def precompile_app_assets
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
    end

    # this method compiles all of the spec files into js files that jasmine can run
    def compile_jasmine_javascripts
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
    end

  end
end
