# Minitest finds this file by its name. Minitest 5 loads it on its own
# when the gem is installed; `Minitest.load :minitap` loads it too.
#
# Requiring `minitap` registers the plugin as a module where Minitest
# supports that (5.24 and newer). The methods below are for older
# versions, which only know plugins by name.

require 'minitap'

module Minitest

  def self.plugin_minitap_options(opts, options)
    Minitap.minitest_plugin_options(opts, options) unless Minitap.registered?
  end

  def self.plugin_minitap_init(options)
    Minitap.minitest_plugin_init(options) unless Minitap.registered?
  end

end
