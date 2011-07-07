require 'fcntl'
require 'tmpdir'
require 'logger'

module Raemon
  autoload :Configuration, 'raemon/configuration'
  autoload :Master,        'raemon/master'
  autoload :Worker,        'raemon/worker'
  autoload :Server,        'raemon/server'
  autoload :Util,          'raemon/util'

  # @return [Logger] the logger used by this library
  def self.logger
    Configuration.logger
  end

  # @yield [Raemon::Configuration] a block that allows for convenient configuration
  #
  # @example
  #   Raemon.config do |c|
  #     c.server_name = 'My Server'
  #   end
  #
  # @see Raemon::Configuration
  def self.config
    yield Configuration
  end
end
