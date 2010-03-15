require 'fcntl'
require 'tmpdir'
require 'logger'

module Raemon
  VERSION = '0.2.0'
  
  autoload :Master, 'raemon/master'
  autoload :Worker, 'raemon/worker'
  autoload :Server, 'raemon/server'
  autoload :Util,   'raemon/util'
end
