# TAP-Y

Given a test file:

    require 'minitest/autorun'
    require 'minitap'

    class ExampleTest < Minitest::Test
      def test_error
        raise "boom"
      end

      def test_failing
        assert_equal('1', '2')
      end

      def test_passing
        assert_equal('1', '1')
      end
    end

Running it with the `--tapy` option gives a TAP-Y stream.

    stream = run_tapy('--tapy')

There are six documents in it.

    stream.size  #=> 6

The first is a `suite` with a count of `3`.

    stream.first['type']   #=> 'suite'
    stream.first['count']  #=> 3
    stream.first['rev']    #=> 4

The second is a `case`, named after the test class.

    stream[1]['type']   #=> 'case'
    stream[1]['label']  #=> 'ExampleTest'
    stream[1]['level']  #=> 0

The next three are the tests, which can come in any order.

    tests = tests(stream)

    tests.size  #=> 3

The passing test has little to say.

    tests['test_passing']['status']     #=> 'pass'
    tests['test_passing']['exception']  #=> nil

The failing test says what failed and where in the test file.

    failing = tests['test_failing']

    failing['status']               #=> 'fail'
    failing['exception']['class']   #=> 'Minitest::Assertion'
    failing['exception']['file']    #=> 'test.rb'
    failing['exception']['line']    #=> 10
    failing['exception']['source']  #=> "assert_equal('1', '2')"

    failing['exception']['message'].assert.include?('Expected: "1"')

It comes with the lines around the failure.

    failing['exception']['snippet'].map { |line| line.keys.first }  #=> [8, 9, 10, 11, 12]
    failing['exception']['snippet'][2][10]  #=> "    assert_equal('1', '2')"

The test that raised an error names the error, not Minitest's wrapper
for it.

    erring = tests['test_error']

    erring['status']               #=> 'error'
    erring['exception']['class']   #=> 'RuntimeError'
    erring['exception']['message'] #=> 'boom'
    erring['exception']['file']    #=> 'test.rb'
    erring['exception']['line']    #=> 6
    erring['exception']['source']  #=> 'raise "boom"'

Neither backtrace mentions Minitest or Minitap.

    failing['exception']['backtrace']  #=> ['test.rb:10']
    erring['exception']['backtrace']   #=> ['test.rb:6']

The last document is the `final` one, with the counts.

    stream.last['type']    #=> 'final'
    stream.last['counts']  #=> {'total'=>3, 'pass'=>1, 'fail'=>1, 'error'=>1, 'omit'=>0, 'todo'=>0}

The stream ends with the YAML end-of-document marker.

    @stdout.lines.last  #=> "...\n"

Nothing else is written, and the exit status still tells of the
failures.

    @stderr  #=> ''
    @status.success?  #=> false
