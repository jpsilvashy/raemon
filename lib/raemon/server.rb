module Raemon
  module Server
    extend self

    def config
      Raemon::Configuration
    end

    def run
      yield config if block_given?
    end

    def startup!
      initialize_application

      # Check if the server is already running
      if running?
        config.logger.error "Error: #{server_name} is already running."
        exit
      end

      # Start the master daemon
      config.logger.info "=> Booting #{server_name} (#{config.env})"

      Raemon::Master.start(config.num_workers, worker_class, {
        :name         => config.name,
        :pid_file     => pid_file,
        :detach       => config.detach,
        :logger       => config.logger,
        :timeout      => config.timeout,
        :memory_limit => config.memory_limit
      })
    end

    def shutdown!
      Raemon::Master.stop :pid_file => pid_file
    end

    def console!
      initialize_application
    end

    def initialize_application
      load_environment
      load_initializers
      load_lib

      initialize_logger
    end

    def initialize_logger
      if config.detach?
        config.logger = ::Logger.new("#{RAEMON_ROOT}/log/#{server_name_key}.log")
      end
    end

    def load_environment
      environment_file = "#{RAEMON_ROOT}/config/environments/#{RAEMON_ENV}.rb"
      eval IO.read(environment_file), binding
    end

    def load_initializers
      load_folder "#{RAEMON_ROOT}/config/initializers"
    end

    def load_lib
      libdir = "#{RAEMON_ROOT}/lib"
      $LOAD_PATH.unshift libdir
      load_folder libdir
    end

    def pid_file
      "#{RAEMON_ROOT}/tmp/pids/#{server_name_key}.pid"
    end

    def running?
      pid = File.read(pid_file).to_i rescue 0
      Process.kill(0, pid) if pid > 0
    rescue Errno::ESRCH
    end

    private

    def load_folder(path)
      Dir["#{path}/**/*.rb"].each { |file| require(file) }
    end

    def server_name_key
      config.name.downcase.gsub(' ', '_')
    end

    def worker_class
      instance_eval(config.worker_class)
    end
  end
end
