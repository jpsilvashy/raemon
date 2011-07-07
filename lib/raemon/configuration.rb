module Raemon
  ##
  # Manages configuration settings and defaults
  module Configuration
    extend self

    DEFAULT_NAME = "Raemon"

    DEFAULT_DETATCH = false

    DEFAULT_NUM_WORKERS = 1

    DEFAULT_TIMEOUT = 3 * 60 # 3 minutes

    attr_accessor :settings
    @settings = {}

    # Define a configuration option with a default.
    #
    # @example Define the option.
    #   Config.option(:name, default: "Raemon")
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

    option :name, :default => DEFAULT_NAME

    option :detatch, :default => DEFAULT_DETATCH

    option :num_workers, :default => DEFAULT_NUM_WORKERS

    option :logger, :default => ::Logger.new($stdout)

    option :timeout, :default => DEFAULT_TIMEOUT

    option :worker_class

    option :memory_limit
  end
end
