# Be sure to restart your daemon when you modify this file
require 'rubygems'
require 'bundler'

Bundler.setup

require 'raemon'

Raemon.config do |config|
  config.server_name  = 'Queued'
  config.worker_class = 'Queued::Worker'
  config.num_workers  = 1
  config.root         = File.expand_path(File.join(File.dirname(__FILE__), '..'))
end

Bundler.require(:default, Raemon.env)

Raemon::Server.boot!
