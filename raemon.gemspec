version = File.read("VERSION").strip

Gem::Specification.new do |s|
  s.name        = 'raemon'
  s.version     = version
  s.platform    = Gem::Platform::RUBY
  s.summary     = "Raemon is a Ruby framework for building UNIX daemons"
  s.description = "Raemon is a Ruby framework for building UNIX daemons"
  
  s.authors     = ["Peter Kieltyka"]
  s.email       = ["peter.kieltyka@nulayer.com"]
  s.homepage    = "http://github.com/nulayer/raemon"

  s.required_rubygems_version = ">= 1.3.6"

  s.files        = Dir['README', 'lib/**/*']
  s.require_path = 'lib'
end
