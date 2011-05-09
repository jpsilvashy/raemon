module Queued
  
  class JobProcessor
    attr_accessor :job

    def self.process(raw_job)
      return if raw_job.nil?
      new(raw_job).process!
    end

    def initialize(job)
      self.job = job
    end
    
    def process!
      Queued.logger.info(job.body)
      job.delete if !job.nil?
    end    
  end

end
