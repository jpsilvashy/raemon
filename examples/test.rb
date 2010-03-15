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

  def runloop
    # @x ||= 1
    
    logger.warn "I'm executing .. #{Process.ppid}:#{Process.pid}"
    sleep 2
    
    # if @x < 4
    #   sleep 2
    # else
    #   sleep 20
    # end    
    # @x += 1
  end

end

Raemon::Master.start 3, Test
