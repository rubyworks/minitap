# Choosing the format in code

The format can be chosen in a test helper instead of on the command
line.

Given a test file:

    require 'minitest/autorun'
    require 'minitap'

    Minitap.tapj!

    class ExampleTest < Minitest::Test
      def test_passing
        assert true
      end
    end

Then it needs no option.

    stream = run_tapj

    stream.map { |d| d['type'] }  #=> ['suite', 'case', 'test', 'final']

An option on the command line takes precedence.

    stream = run_tapy('--tapy')

    stream.map { |d| d['type'] }  #=> ['suite', 'case', 'test', 'final']

## minitap/autorun

Requiring `minitap/autorun` is `minitest/autorun` with TAP-Y chosen.

Given a test file:

    require 'minitap/autorun'

    class ExampleTest < Minitest::Test
      def test_passing
        assert true
      end
    end

Then:

    stream = run_tapy

    stream.map { |d| d['type'] }  #=> ['suite', 'case', 'test', 'final']

Here too an option can ask for the other format.

    stream = run_tapj('--tapj')

    stream.map { |d| d['type'] }  #=> ['suite', 'case', 'test', 'final']

## Without a format

Requiring Minitap chooses nothing by itself.

Given a test file:

    require 'minitest/autorun'
    require 'minitap'

    class ExampleTest < Minitest::Test
      def test_passing
        assert true
      end
    end

Without an option, Minitest reports as it always does.

    out = run_tests

    out.assert.include?('1 runs, 1 assertions, 0 failures, 0 errors, 0 skips')

An unknown format is refused.

    require 'minitap'

    ArgumentError.assert.raised? do
      Minitap.format = :xml
    end

    Minitap.format  #=> nil

## Minitest's plugin loader

Minitest can also be told to load the plugin by name.

Given a test file:

    require 'minitest/autorun'

    Minitest.load :minitap if Minitest.respond_to?(:load)

    class ExampleTest < Minitest::Test
      def test_passing
        assert true
      end
    end

Then the options are there. (Minitest 5 finds an installed plugin
without being told, so there it works either way.)

    stream = run_tapy('--tapy')

    stream.map { |d| d['type'] }  #=> ['suite', 'case', 'test', 'final']
