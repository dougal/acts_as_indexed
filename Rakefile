require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the acts_as_indexed plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the acts_as_indexed plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ActsAsIndexed'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('CHANGELOG')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

namespace :rcov do
  desc "Generate a coverage report in coverage/"
  task :gen do
    sh "rcov --output coverage test/*_test.rb"
  end

  desc "Remove generated coverage files."
  task :clobber do
    sh "rm -rdf coverage"
  end
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
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end

namespace :rvm do
  AR_VERSIONS = %w{2.1.2 2.2.3 2.3.12 3.0.9}
  INSTALLED_GEMSETS = `rvm gemset list`.scan(/aai_ar[^\n]+/)

  desc "Setup RVM gemsets to test different versions of ActiveRecord"
  task :test do
    AR_VERSIONS.each do |version|
      gemset_name = "aai_ar_#{ version }"

      unless INSTALLED_GEMSETS.include?(gemset_name)
        sh "rvm gemset create #{ gemset_name }"
        sh "rvm gemset use aai_ar_#{ version }"
        sh "gem install bundler --no-rdoc --no-ri"
        sh "bundle install"
        sh "gem install activerecord --version #{version} --no-rdoc --no-ri"
      end

      puts "Testing with Activerecord #{ version }"
      puts "="*20
      sh "rake test"
      puts "="*20
    end
  end

  task :cleanup do
    INSTALLED_GEMSETS.each do |gemset|
      sh "rvm --force gemset delete #{ gemset }"
    end
  end

end