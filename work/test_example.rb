require 'minitest/autorun'

#require 'minitap'
#MiniTest::Unit.runner = MiniTest::TapJ.new

#require "minitest/reporters"
#MiniTest::Reporters.use! MiniTest::Reporters::SpecReporter.new

#require 'active_support/core_ext' # why do i have to require this?

class TestThis < Minitest::Test

  def method1
    puts "this will break tapout because of malformed output"
    true
  end

  def method2
    puts "this will also break tapout because of malformed output"
    true
  end

  def test_broken1
    assert method1
  end

  def test_broken2
    assert method2
  end

  def test_fine
    assert true
  end

  def test_not_fine
    assert false
  end

end
