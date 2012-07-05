# encoding: UTF-8
require 'rubygems'
require 'rake'
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

begin
  require 'rdoc/task'
rescue LoadError
  require 'rdoc/rdoc'
  require 'rake/rdoctask'
  RDoc::Task = Rake::RDocTask
end

Bundler::GemHelper.install_tasks

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'websocket-rails'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'rspec/core/rake_task'

desc 'Default: run RSpec and Jasmine specs.'
task :default => :spec_and_jasmine

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = "./spec/**/*_spec.rb"
end

desc "Run rspec and jasmine:ci at the same time"
task :spec_and_jasmine do
  Rake::Task["spec"].execute
  Rake::Task["jasmine:ci:headless"].execute
end

desc "Generate code coverage"
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task["spec"].execute
  `open coverage/index.html`
end

begin
  require 'jasmine'
  load 'jasmine/tasks/jasmine.rake'
rescue LoadError
  task :jasmine do
    abort "Jasmine is not available. In order to run jasmine, you must: (sudo) gem install jasmine"
  end
end

require 'headless'
require 'selenium-webdriver'

namespace :jasmine do
  namespace :ci do
    desc "Run Jasmine CI build headlessly"
    task :headless do
      ENV['DISPLAY'] = ':99.0'
      puts "Running Jasmine Headlessly"
      Rake::Task['jasmine:ci'].invoke
    end
  end
end
