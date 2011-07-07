# Be sure to restart your daemon when you modify this file
require 'rubygems'
require 'bundler'

Bundler.setup

require 'raemon'
Raemon.root = File.expand_path('../../', __FILE__)

Raemon.config do |config|
  config.server_name  = 'Queued'
  config.worker_class = 'Queued::Worker'
  config.num_workers  = 1
end

Bundler.require(:default, Raemon.env)

Raemon::Server.boot!
