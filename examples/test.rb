$:.unshift ::File.dirname(__FILE__) + '/../lib'

require 'rubygems'
require 'raemon'

class Test
  include Raemon::Worker
  
  def start
    logger.info "=> Starting worker #{Process.pid}"
  end

  def stop
    logger.info "=> Stopping worker #{Process.pid}"
  end

  def run
    loop do
      logger.warn "I'm executing .. #{Process.ppid}:#{Process.pid}"
      sleep 2
      
      heartbeat!
    end
  end
end

Raemon::Master.start 3, Test
