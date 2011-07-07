require 'rubygems'
require 'bundler/setup'

require 'simplecov'

SimpleCov.start do
  add_filter 'spec'
end

require 'raemon'

RSpec.configure do |config|
  # Nothing for now
end
