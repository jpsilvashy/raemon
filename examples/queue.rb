# Use the code below to put some jobs onto the queue to test beanstalk.rb
# and evented.rb examples

require 'rubygems'
require 'beanstalk-client'

@queue = Beanstalk::Pool.new(['localhost:11300'])

num_jobs = 20

(0...num_jobs).each do |id|
  job = "Job#{id}"
  @queue.put job
end
