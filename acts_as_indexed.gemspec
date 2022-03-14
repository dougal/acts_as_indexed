Gem::Specification.new do |s|
  s.name = "acts_as_indexed"
  s.version = "0.8.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Douglas F Shearer"]
  s.date = "2013-04-17"
  s.description = "Acts As Indexed is a plugin which provides a pain-free way to add fulltext search to your Ruby on Rails app"
  s.email = "dougal.s@gmail.com"
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    "CHANGELOG",
    "Gemfile",
    "MIT-LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "acts_as_indexed.gemspec",
    "gemfiles/rails2_3.gemfile",
    "gemfiles/rails3_0.gemfile",
    "gemfiles/rails3_1.gemfile",
    "gemfiles/rails3_2.gemfile",
    "lib/acts_as_indexed.rb",
    "lib/acts_as_indexed/class_methods.rb",
    "lib/acts_as_indexed/configuration.rb",
    "lib/acts_as_indexed/instance_methods.rb",
    "lib/acts_as_indexed/pre_tokenizer.rb",
    "lib/acts_as_indexed/search_atom.rb",
    "lib/acts_as_indexed/search_index.rb",
    "lib/acts_as_indexed/singleton_methods.rb",
    "lib/acts_as_indexed/storage.rb",
    "lib/acts_as_indexed/token_normalizer.rb",
    "lib/acts_as_indexed/tokenizer.rb",
    "lib/will_paginate_search.rb",
    "rails/init.rb",
    "test/config/database.yml",
    "test/db/schema.rb",
    "test/fixtures/post.rb",
    "test/fixtures/posts.yml",
    "test/integration/acts_as_indexed_test.rb",
    "test/integration/will_paginate_search_test.rb",
    "test/integration_test_helper.rb",
    "test/performance/query_performance_test.rb",
    "test/performance/record_addition_performance_test.rb",
    "test/performance/record_removal_performance_test.rb",
    "test/performance/record_update_performance_test.rb",
    "test/unit/configuration_test.rb",
    "test/unit/pre_tokenizer_test.rb",
    "test/unit/search_atom_test.rb",
    "test/unit/search_index_test.rb",
    "test/unit/token_normalizer_test.rb",
    "test/unit/tokenizer_test.rb",
    "test/unit_test_helper.rb"
  ]
  s.homepage = "http://github.com/dougal/acts_as_indexed"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "Acts As Indexed is a plugin which provides a pain-free way to add fulltext search to your Ruby on Rails app"
end

