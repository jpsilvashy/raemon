module Raemon
  class Configuration
    ATTRIBUTES = [ :name, :detach, :num_workers, :worker_klass,
                   :log_level, :logger, :timeout, :memory_limit ]

    attr_accessor *ATTRIBUTES

    def [](key)
      send key rescue nil
    end
  end
end
