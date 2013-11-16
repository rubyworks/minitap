gem "minitest", "~> 5.0"

require 'minitest'
require 'minitest/reporter_api'
require 'minitap/minitest5'

module Minitap
  TapY = Minitest::TapY
  TapJ = Minitest::TapJ
end

