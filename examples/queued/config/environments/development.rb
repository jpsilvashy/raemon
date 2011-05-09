config.detach       = false
config.num_workers  = 5
config.log_level    = :debug

begin
  require 'ruby-debug'
rescue LoadError
end
