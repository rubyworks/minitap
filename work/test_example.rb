require 'minitap'
MiniTest::Unit.runner = MiniTest::TapJ.new
require 'minitest/autorun'
#require 'active_support/core_ext' # why do i have to require this?

class TestThis < MiniTest::Unit::TestCase

  def my_method
    puts "this will break tapout because of malformed output"
    true
  end

  def test_broken
    assert my_method
  end

end
