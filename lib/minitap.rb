require 'minitest'
require 'minitap/version'
require 'minitap/reporter'

# Minitap makes Minitest report in TAP-Y or TAP-J, the formats that
# Tapout reads. It is a Minitest plugin.
#
# Choose the format on the command line, with `--tapy` or `--tapj`, or
# in a test helper:
#
#     require 'minitest/autorun'
#     require 'minitap'
#
#     Minitap.tapy!
#
module Minitap

  # The reporter for each format, by the format's name.
  FORMATS = { 'tapy' => TapY, 'tapj' => TapJ }

  @format     = nil
  @registered = false

  class << self

    # The format chosen in code, 'tapy' or 'tapj', or nil. A `--tapy`
    # or `--tapj` option on the command line takes precedence over it.
    attr_reader :format

    # Choose the format: :tapy, :tapj, or nil for Minitest's own report.
    def format=(name)
      name = name.to_s.downcase.delete('-_') unless name.nil?
      unless name.nil? || FORMATS.key?(name)
        raise ArgumentError, "unknown format #{name.inspect}, use :tapy or :tapj"
      end
      @format = name
    end

    # Report in TAP-Y.
    def tapy!
      self.format = :tapy
    end

    # Report in TAP-J.
    def tapj!
      self.format = :tapj
    end

    # Called by Minitest to add this plugin's command line options.
    def minitest_plugin_options(opts, options)
      opts.on '--tapy', 'Report in TAP-Y, for Tapout.' do
        options[:minitap] = 'tapy'
      end
      opts.on '--tapj', 'Report in TAP-J, for Tapout.' do
        options[:minitap] = 'tapj'
      end
    end

    # Called by Minitest as a run starts. If a format was chosen, its
    # reporter takes the place of Minitest's own reporters, whose
    # output would corrupt the stream.
    def minitest_plugin_init(options)
      format = options[:minitap] || self.format
      return unless format

      composite = Minitest.reporter
      return if composite.reporters.any? { |r| Reporter === r }

      composite.reporters.clear
      composite << FORMATS.fetch(format.to_s).new(options[:io], options)
    end

    # Has Minitap been registered with Minitest as a plugin module?
    def registered?
      @registered
    end

    # Register with Minitest. Minitest 5.24 and newer take a module.
    # Older versions find `minitest/minitap_plugin.rb` on their own.
    def register
      return if registered?
      return unless Minitest.respond_to?(:register_plugin)
      Minitest.register_plugin(self)
      @registered = true
    end

  end

  register

end
