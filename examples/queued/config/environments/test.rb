config.detach       = false
config.num_workers  = 1
config.log_level    = :debug

begin
  require 'ruby-debug'
rescue LoadError
end
