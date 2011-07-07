module Raemon
  ##
  # Manages configuration settings and defaults
  module Configuration
    extend self

    ATTRIBUTES = [ :name, :detach, :num_workers, :worker_klass,
                   :log_level, :logger, :timeout, :memory_limit ]

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
  end
end
