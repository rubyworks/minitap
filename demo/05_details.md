# Details

## Skipped tests

Given a test file:

    require 'minitest/autorun'
    require 'minitap'

    class ExampleTest < Minitest::Test
      def test_skipped
        skip "not today"
      end

      def test_passing
        assert true
      end
    end

A skipped test has the status `omit`, which is what TAP-Y/J calls it,
and gives the reason.

    stream = run_tapy('--tapy')
    tests  = tests(stream)

    tests['test_skipped']['status']                #=> 'omit'
    tests['test_skipped']['exception']['message']  #=> 'not today'
    tests['test_skipped']['exception']['file']     #=> 'test.rb'
    tests['test_skipped']['exception']['line']     #=> 6

    stream.last['counts']  #=> {'total'=>2, 'pass'=>1, 'fail'=>0, 'error'=>0, 'omit'=>1, 'todo'=>0}

A skip is not a failure.

    @status.success?  #=> true

## Output from tests

Given a test file:

    require 'minitest/autorun'
    require 'minitap'

    class ExampleTest < Minitest::Test
      def test_noisy
        puts "to stdout"
        warn "to stderr"
        assert true
      end

      def test_quiet
        assert true
      end
    end

What a test prints would break the stream. It is captured and becomes
part of the test's record.

    stream = run_tapy('--tapy')
    tests  = tests(stream)

    tests['test_noisy']['stdout']  #=> "to stdout\n"
    tests['test_noisy']['stderr']  #=> "to stderr\n"

    tests['test_quiet'].key?('stdout')  #=> false
    tests['test_quiet'].key?('stderr')  #=> false

    @stderr  #=> ''

## Several classes

Given a test file:

    require 'minitest/autorun'
    require 'minitap'

    class FirstTest < Minitest::Test
      def test_one; assert true; end
      def test_two; assert true; end
    end

    class SecondTest < Minitest::Test
      def test_three; assert true; end
    end

Each class is a case, followed by its tests.

    stream = run_tapy('--tapy')

    cases = stream.select { |d| d['type'] == 'case' }.map { |d| d['label'] }

    cases.sort  #=> ['FirstTest', 'SecondTest']

    types = stream.map { |d| d['type'] }
    index = stream.index { |d| d['label'] == 'FirstTest' }

    types[index, 3]  #=> ['case', 'test', 'test']

    stream.first['count']  #=> 3

## Selecting tests by name

The count at the start of the stream is of the tests that will run,
so it follows Minitest's `--name` option.

    stream = run_tapy('--tapy', '--name', '/one|three/')

    stream.first['count']            #=> 2
    stream.last['counts']['total']   #=> 2

    tests(stream).keys.sort  #=> ['test_one', 'test_three']

## The seed

The seed is in the `suite` document, and the tests run in the order
that seed gives them without Minitap.

    stream = run_tapy('--tapy', '--seed', '42')

    stream.first['seed']  #=> 42

    with = stream.select { |d| d['type'] == 'test' }.map { |d| d['label'] }

    plain   = run_tests('--seed', '42', '--verbose')
    without = plain.scan(/^\w+Test#(test_\w+)/).flatten

    with  #=> without
