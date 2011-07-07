require 'rubygems'
require 'bundler/setup'

require 'simplecov'

SimpleCov.start do
  add_filter 'spec'
end

require 'raemon'

RSpec.configure do |config|
  config.before(:all) do
    Raemon.config do |c|
      c.root   = '.'
      c.logger = ::Logger.new('/dev/null')
    end
  end
end
