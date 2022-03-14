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
    rdoc.options << '--line-numbers' << '--inline-source'
    rdoc.rdoc_files.include('README.rdoc')
    rdoc.rdoc_files.include('CHANGELOG')
    rdoc.rdoc_files.include('lib/**/*.rb')
  end
rescue LoadError
  puts "sdoc not installed"
end
