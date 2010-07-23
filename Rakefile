require 'rubygems'
require 'rake'
require 'rake/testtask'
# require 'rake/rdoctask'
require 'rake/gempackagetask'

# Rake::TestTask.new do |test|
#   test.libs << 'test'
#   test.pattern = 'test/**/*_test.rb'
#   test.verbose = true
# end

spec = eval(File.read('raemon.gemspec'))
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end
