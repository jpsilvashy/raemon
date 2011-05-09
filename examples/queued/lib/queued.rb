require 'beanstalk-client'

module Queued
  
  class << self
    attr_accessor :logger, :queue
  end
  
  autoload :Worker, 'queued/worker'
  autoload :JobProcessor, 'queued/job_processor'

end
