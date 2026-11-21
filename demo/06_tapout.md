# Tapout

The stream is for Tapout, which renders it in a format of your choice.

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

      def test_skipped
        skip "not today"
      end
    end

Tapout reads the TAP-Y stream.

    out = tapout(run_tests('--tapy', '--seed', '1'), 'tap')

    out.assert.include?('1..4')
    out.assert =~ /^ok \d - test_passing$/
    out.assert =~ /^not ok \d - test_failing$/
    out.assert =~ /^not ok \d - test_error$/
    out.assert =~ /^ok \d - test_skipped # SKIP not today$/

And the TAP-J stream.

    out = tapout(run_tests('--tapj', '--seed', '1'), 'tap')

    out.assert =~ /^ok \d - test_passing$/
    out.assert =~ /^not ok \d - test_failing$/
    out.assert =~ /^ok \d - test_skipped # SKIP not today$/
