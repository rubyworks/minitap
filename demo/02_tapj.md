# TAP-J

Given a test file:

    require 'minitest/autorun'
    require 'minitap'

    class ExampleTest < Minitest::Test
      def test_failing
        assert_equal('1', '2')
      end

      def test_passing
        assert_equal('1', '1')
      end
    end

Running it with the `--tapj` option gives a TAP-J stream: the same
records as TAP-Y, as a JSON document on each line.

    stream = run_tapj('--tapj')

    stream.map { |d| d['type'] }  #=> ['suite', 'case', 'test', 'test', 'final']

    tests = tests(stream)

    tests['test_passing']['status']             #=> 'pass'
    tests['test_failing']['status']             #=> 'fail'
    tests['test_failing']['exception']['file']  #=> 'test.rb'
    tests['test_failing']['exception']['line']  #=> 6

    stream.last['counts']  #=> {'total'=>2, 'pass'=>1, 'fail'=>1, 'error'=>0, 'omit'=>0, 'todo'=>0}
