require 'minitap/minitest5'

module Minitest

  class MinitapReporter

    class << self
      attr_accessor :reporter
    end

    def self.use(reporter=TapJ.new, options={})
      self.reporter = reporter
    end
  end
end