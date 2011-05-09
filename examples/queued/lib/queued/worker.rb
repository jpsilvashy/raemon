module Queued
  
  class Worker
    include Raemon::Worker
    
    def start
      Queued.logger = logger
      logger.info "=> Starting worker #{Process.pid}"
    end

    def stop
      logger.info "=> Stopping worker #{Process.pid}"
    end

    def run
      begin
        # Connect to queue
        Queued.queue = Beanstalk::Pool.new([SETTINGS['beanstalk']['host']])
        Queued.queue.use(SETTINGS['beanstalk']['channel'])
        Queued.queue.watch(SETTINGS['beanstalk']['channel'])
        
        # Process jobs
        loop do
          heartbeat! # Let the master know we're alive and well
        
          begin
            raw_job = Queued.queue.reserve(20) # Wait for 20 sec to get a job
          rescue Beanstalk::TimedOut
            next
          end
        
          JobProcessor.process(raw_job)
        end
      rescue => ex
        error_handler(ex)
      end

      logger.error "=> Unexpected worker exit #{Process.pid}"
    end
    
    def error_handler(ex)
      case ex
      when Beanstalk::NotConnected
        logger.error "Cannot connect to the job queue."
      else
        logger.error ex.message
        logger.error ex.backtrace.join("\n")
      end
    end
  end
  
end
