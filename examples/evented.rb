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
  
  def execute
    runloop(:evented) do
      @queue = EMJack::Connection.new
      
      @queue.each_job(5) do |job|        
        logger.info "(#{Process.ppid}:#{Process.pid}) got job: #{job.inspect}"
        # process(job)
        @queue.delete(job)
        
        worker_pulse!
        
        # stop if shutting_down?
      end
      
      # @queue.on_error do |error|
      #   case error
      #   when :timed_out
      #     # We use the reserve timeout to check if we should shutdown
      #     stop if shutting_down?
      #   else
      #     logger.error error.to_s
      #   end
      # end
    end
  end
  
  def execute2
    EventMachine.run do
      @queue = EMJack::Connection.new
      
      @queue.each_job(5) do |job|        
        logger.info "(#{Process.ppid}:#{Process.pid}) got job: #{job.inspect}"
        # process(job)
        @queue.delete(job)
        
        # stop if shutting_down?
      end
      
      @queue.on_error do |error|
        case error
        when :timed_out
          # We use the reserve timeout to check if we should shutdown
          stop if shutting_down?
        else
          logger.error error.to_s
        end
      end
    end
  end

end

Raemon::Master.start 2, EventedJobWorker

# __END__

# Use the code below to put some jobs onto the queue to test the daemon

require 'rubygems'
require 'beanstalk-client'

@queue = Beanstalk::Pool.new(['localhost:11300'])


num_jobs = 10

(0...num_jobs).each do |id|
  job = "Job#{id}"
  @queue.put job
end













