module Raemon
  ##
  # Manages configuration settings and defaults
  module Configuration
    extend self

    DEFAULT_SERVER_NAME = 'Raemon'

    DEFAULT_DETACH = false

    DEFAULT_NUM_WORKERS = 1

    DEFAULT_TIMEOUT = 3 * 60 # 3 minutes

    DEFAULT_MEMORY_LIMIT_IN_MEGABYTES = 50

    DEFAULT_ENVIRONMENT = 'development'

    attr_accessor :settings
    @settings = {}

    # Define a configuration option with a default.
    #
    # @example Define the option.
    #   Config.option(:server_name, default: "Raemon")
    #
    # @param [Symbol] name The name of the configuration option
    #
    # @param [Hash] options Extras for the option
    #
    # @note Copied from Mongoid. Thank you!
    #
    # @private
    def option(name, options = {})
      define_method(name) do
        settings.has_key?(name) ? settings[name] : options[:default]
      end

      define_method("#{name}=") { |value| settings[name] = value }
      define_method("#{name}?") { !!send(name) }
    end

    option :server_name, :default => DEFAULT_SERVER_NAME

    option :detach, :default => DEFAULT_DETACH

    option :num_workers, :default => DEFAULT_NUM_WORKERS

    option :logger, :default => ::Logger.new($stdout)

    option :timeout, :default => DEFAULT_TIMEOUT

    option :env, :default => DEFAULT_ENVIRONMENT

    option :memory_limit, :default => DEFAULT_MEMORY_LIMIT_IN_MEGABYTES

    option :worker_class

    # @param [String] root The root path for this application
    def root=(root)
      @root = root
    end

    # @return [Pathname] the root path for this application
    def root
      if @root.nil?
        raise 'Raemon::Config.root must be set'
      else
        Pathname.new(@root).expand_path
      end
    end
  end
end
