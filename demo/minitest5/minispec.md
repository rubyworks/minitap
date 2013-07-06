# Minitap 

Given a Minitest Spec:

    require 'minitest/spec'

    describe "Example Case" do
      it "should error" do
        raise
      end

      it "should fail" do
        assert_equal('1', '2')
      end

      it "should pass" do
        sleep 1
        assert_equal('1', '1')
      end
    end

Running it with the TAP-Y format should work without error.

The resulting document stream should exhibit the following
characteristics.

There should be six sections.

    @stream.size  #=> 6

The first should be a `suite` with a count of `3`.

    @stream.first['type']   #=> 'suite'
    @stream.first['count']  #=> 3

The second should be `case` entry.

    @stream[1]['type']   #=> 'case'
    @stream[1]['label']  #=> 'Example Case'
    @stream[1]['level']  #=> 0

The next three documents are the unit tests, which can occur in any order.
There's one that should have a status of `pass`, another of `fail` and the
third of `error`.

    passing_test = @stream.find{ |d| d['type'] == 'test' && d['status'] == 'pass' }
    failing_test = @stream.find{ |d| d['type'] == 'test' && d['status'] == 'fail' }
    erring_test  = @stream.find{ |d| d['type'] == 'test' && d['status'] == 'error' }

The passing test should have the following charactersitics.

    passing_test['label']  #=> 'should pass'

The failing test should

    failing_test['label']               #=> "should fail"
    failing_test['exception']['class']  #=> "Minitest::Assertion"
    failing_test['exception']['file']   #=> "test.rb"
    failing_test['exception']['line']   #=> 16
    failing_test['exception']['source'] #=> "assert_equal('1', '2')"

The failing test should also not have any mention of minitap in the
backtrace.

    failing_test['exception']['backtrace'].each do |e|
      /minitap/.refute.match(e)
    end

The erring test should 

    erring_test['label']               #=> 'should error'
    erring_test['exception']['class']  #=> 'RuntimeError'
    erring_test['exception']['file']   #=> 'test.rb'
    erring_test['exception']['line']   #=> 12
    erring_test['exception']['source'] #=> 'raise'

The erring test should also not have any mention of minitap in the
backtrace.

    erring_test['exception']['backtrace'].each do |e|
      /minitap/.refute.match(e)
    end

The last should a `final` document.

    @stream.last['type']  #=> 'final'

And it should have the following counts.

    @stream.last['counts']['total']  #=> 3
    @stream.last['counts']['error']  #=> 1
    @stream.last['counts']['fail']   #=> 1
    @stream.last['counts']['pass']   #=> 1
    @stream.last['counts']['omit']   #=> 0
    @stream.last['counts']['todo']   #=> 0

