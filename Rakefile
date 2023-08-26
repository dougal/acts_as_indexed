require 'rake'
require 'rake/testtask'

desc 'Default: run all tests.'
task :default => :test

desc 'Run all tests.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/integration/*_test.rb', 'test/unit/*_test.rb']
  t.verbose = true
end

desc 'Run unit tests.'
Rake::TestTask.new('test:unit') do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.pattern = 'test/unit/*_test.rb'
  t.verbose = true
end

desc 'Run integration tests.'
Rake::TestTask.new('test:integration') do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.pattern = 'test/integration/*_test.rb'
  t.verbose = true
end

desc 'Run temp tests.'
Rake::TestTask.new('test:temp') do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.pattern = 'test/integration/will_paginate_search_test.rb'
  t.verbose = true
end

desc 'Run performance tests.'
Rake::TestTask.new('test:performance') do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.pattern = 'test/performance/*_test.rb'
  t.verbose = true
end

begin
  require 'sdoc'

  desc 'Generate documentation for the acts_as_indexed plugin.'
  RDoc::Task.new(:rdoc) do |rdoc|
    rdoc.rdoc_dir = 'rdoc'
    rdoc.title    = 'ActsAsIndexed'
    rdoc.main     = "README.md"
    rdoc.options << "--line-numbers"

    rdoc.rdoc_files.include('README.md')
    rdoc.rdoc_files.include('CHANGELOG.md')
    rdoc.rdoc_files.include('lib/**/*.rb')
  end
rescue LoadError
  puts "sdoc not installed"
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "acts_as_indexed"
    gemspec.summary = "Acts As Indexed is a plugin which provides a pain-free way to add fulltext search to your Ruby on Rails app"
    gemspec.description = gemspec.summary
    gemspec.email = "dougal.s@gmail.com"
    gemspec.homepage = "http://github.com/dougal/acts_as_indexed"
    gemspec.authors = ["Douglas F Shearer"]
    gemspec.files.exclude ".github/**/*"
    gemspec.files.exclude ".travis.yml"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end
