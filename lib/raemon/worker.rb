module Raemon
  module Worker
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      attr_reader :master, :logger, :id, :pid, :pulse

      def initialize(master, id, pulse)
        @master = master
        @logger = master.logger
        @id     = id
        @pid    = Process.pid
        @pulse  = pulse
      end

      def ==(other_id)
        @id == other_id
      end

      def run
        raise NotImplementedError, "must be implemented in your class"
      end

      def heartbeat!
        master.worker_heartbeat!(self)
      end
    end
  end
end
