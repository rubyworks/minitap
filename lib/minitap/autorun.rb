# Run the tests when the program exits, reporting in TAP-Y unless
# another format has been chosen.

require 'minitest/autorun'
require 'minitap'

Minitap.tapy! unless Minitap.format
