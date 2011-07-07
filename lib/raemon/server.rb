module Raemon
  module Server
    extend self

    # Initializes application components without starting the master process
    def boot!
      load_environment
      load_lib # Must be second so that initializers have access to lib
      load_initializers

      initialize_logger
    end

    # Start the master daemon. Exits the script if the master daemon is
    # already running.
    def startup!
      stop_if_running!
      start_master_daemon
    end

    # Stop the master daemon
    def shutdown!
      stop_master_daemon
    end

    # @return [Pathname] the target PID file
    def pid_file
      config.root.join("tmp/pids/#{server_name_key}.pid")
    end

    private

      def running?
        pid = File.read(pid_file).to_i rescue 0
        Process.kill(0, pid) if pid > 0
      rescue Errno::ESRCH
      end

      def stop_if_running!
        if running?
          config.logger.error "Error: #{config.server_name} is already running."
          exit
        end
      end

      def start_master_daemon
        config.logger.info "=> Booting #{config.server_name} (#{config.env})"

        Raemon::Master.start(config.num_workers, worker_class, {
          :name         => config.server_name,
          :pid_file     => pid_file,
          :detach       => config.detach,
          :logger       => config.logger,
          :timeout      => config.timeout,
          :memory_limit => config.memory_limit
        })
      end

      def stop_master_daemon
        Raemon::Master.stop(:pid_file => pid_file)
      end

      def initialize_logger
        if config.detach?
          config.logger = ::Logger.new(config.root.join("log/#{server_name_key}.log"))
        end
      end

      def load_environment
        environment_file = config.root.join("config/environments/#{config.env}.rb")
        eval File.read(environment_file), binding
      end

      def load_initializers
        load_folder(config.root.join("config/initializers"))
      end

      def load_lib
        libdir = config.root.join("lib")

        $LOAD_PATH.unshift libdir
        load_folder libdir
      end

      def config
        Raemon::Configuration
      end

      def load_folder(path)
        Dir["#{path}/**/*.rb"].each { |file| require(file) }
      end

      def server_name_key
        config.server_name.downcase.gsub(' ', '_')
      end

      def worker_class
        instance_eval(config.worker_class)
      end
  end
end
