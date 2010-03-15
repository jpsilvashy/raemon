$:.unshift ::File.dirname(__FILE__) + '/../lib'

require 'rubygems'
require 'raemon'
require 'em-jack'

class EventedJobWorker
  include Raemon::Worker
  
  def start
    logger.info "=> Starting worker #{Process.pid}"
  end
  
  def stop
    logger.info "=> Stopping worker #{Process.pid}"
    
    EM.stop_event_loop if EM.reactor_running?
  end
  
  def run
    EM.run do
      @queue = EMJack::Connection.new
      
      @queue.each_job(5) do |job|        
        logger.info "(#{Process.ppid}:#{Process.pid}) got job: #{job.inspect}"
        # process(job)
        @queue.delete(job)
        
        heartbeat!
      end
      
      @queue.on_error do |error|
        case error
        when :timed_out
          # We use the reserve timeout for the heartbeat
          heartbeat!
          
          # Note: this will only run once.. we need to call the @queue.each_job
          # again .. maybe put it in a block
        else
          logger.error error.to_s
        end
      end
    end
  end

end

Raemon::Master.start 2, EventedJobWorker
