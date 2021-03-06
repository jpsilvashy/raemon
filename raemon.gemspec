# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'raemon/version'

Gem::Specification.new do |s|
  s.name        = 'raemon'
  s.version     = Raemon::VERSION
  s.platform    = Gem::Platform::RUBY
  s.summary     = "Raemon is a Ruby framework for building UNIX daemons"
  s.description = "Raemon is a Ruby framework for building UNIX daemons"

  s.authors     = ["Peter Kieltyka"]
  s.email       = ["peter.kieltyka@nulayer.com"]
  s.homepage    = "http://github.com/nulayer/raemon"

  s.files        = Dir['README', 'lib/**/*']
  s.require_path = 'lib'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec',            ['~> 2.6.0']
  s.add_development_dependency 'simplecov',        ['~> 0.4.2']
  s.add_development_dependency 'em-jack',          ['~> 0.1.3']
  s.add_development_dependency 'beanstalk-client', ['~> 1.1.0']
end
