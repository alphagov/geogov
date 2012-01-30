# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name          = "geogov"
  s.version       = "0.0.9"

  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Ben Griffiths", "James Stewart"]
  s.email         = ["ben@alphagov.co.uk", "jystewart@gmail.com"]
  s.homepage      = "http://github.com/alphagov/geogov"
  s.summary       = %q{Geolocation and utilities for UK Government single domain}
  s.description   = %q{Geolocation and utilities for UK Government single domain}

  s.files         = Dir[
    'lib/**/*',
    'README.md',
    'Gemfile',
    'Rakefile'
  ]
  s.test_files    = Dir['test/**/*']
  s.require_paths = ["lib"]

  s.add_development_dependency 'rake', '~> 0.9.0'
  s.add_development_dependency 'mocha', '~> 0.9.0'
end
