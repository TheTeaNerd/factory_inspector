# -*- encoding: utf-8 -*-
require File.expand_path('../lib/factory_inspector/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['David Kennedy']
  gem.email         = ['dave@dkennedy.org']
  gem.description   = 'How often is FactoryGirl being used during your tests?'
  gem.summary       = 'How often is FactoryGirl being used during your tests?'
  gem.homepage      = 'https://github.com/TheTeaNerd/factory_inspector'

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(/^bin\//).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(/^(test|spec|features)\//)
  gem.name          = 'factory_inspector'
  gem.require_paths = ['lib']
  gem.version       = FactoryInspector::VERSION

  gem.add_runtime_dependency 'activesupport'
  gem.add_runtime_dependency 'term-ansicolor'
  gem.add_runtime_dependency 'chronic_duration'
  gem.add_runtime_dependency 'hashr'
  gem.add_runtime_dependency 'method_profiler'

  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'pry'
end
