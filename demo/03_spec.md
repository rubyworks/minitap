# Minitest::Spec

Given a test file:

    require 'minitest/autorun'
    require 'minitap'

    describe "Example Case" do
      it "should error" do
        raise "boom"
      end

      it "should fail" do
        assert_equal('1', '2')
      end

      it "should pass" do
        assert_equal('1', '1')
      end
    end

A spec is reported like any other test.

    stream = run_tapy('--tapy')

    stream.size  #=> 6

The case is labelled with the description.

    stream[1]['type']   #=> 'case'
    stream[1]['label']  #=> 'Example Case'

The tests are labelled as they were written, without the `test_0001_`
that Minitest puts in front.

    tests = tests(stream)

    tests.keys.sort  #=> ['should error', 'should fail', 'should pass']

    tests['should pass']['status']   #=> 'pass'
    tests['should fail']['status']   #=> 'fail'
    tests['should error']['status']  #=> 'error'

    tests['should fail']['exception']['line']   #=> 10
    tests['should error']['exception']['line']  #=> 6
