# MiniTest adaptor for tapout.

# Have to make sure the latest version of minitest is used.
begin; gem 'minitest'; rescue; end

#require 'minitest/unit'
require 'minitap/ignore_callers'
require 'stringio'

# Becuase of some wierdness in MiniTest
#debug, $DEBUG = $DEBUG, false
#require 'minitest/unit'
#$DEBUG = debug

module Minitest

  ##
  # Base class for TapY and TapJ runners.
  #
  class Minitap < StatisticsReporter #Reporter

    # TAP-Y/J Revision
    REVISION = 4

    # Backtrace patterns to be omitted.
    IGNORE_CALLERS = $RUBY_IGNORE_CALLERS

    # Test results.
    #attr_reader :test_results

    attr_reader :test_cases
    attr_reader :test_count

    attr_accessor :suite_start_time
    attr_accessor :case_start_time
    attr_accessor :test_start_time

    # Initialize new Minitap Minitest reporter.
    def initialize(options = {})
      io = options.delete(:io) || $stdout

      super(io, options)

      # since tapout uses a unix pipe, we don't want any buffering
      io.sync = true

      #@_stdout = StringIO.new
      #@_stderr = StringIO.new

      #@test_results = {}
      #self.assertion_count = 0

      @_source_cache = {}
    end

    #
    # Minitest's initial hook ran just before testing begins.
    #
    def start
      super

      @test_cases = Runnable.runnables

      capture_io

      #@_stdout, @_stderr = capture_io do
      #  super_result = super(suite, type)
      #end

      before_suite(@test_cases)
    end

    #
    # Process a test result.
    #
    def record(minitest_result)
      super(minitest_result)

      result = TestResult.new(minitest_result)

      #if exception #&& ENV['minitap_debug']
      #  STDERR.puts exception
      #  STDERR.puts exception.backtrace.join("\n")
      #end

      #@test_results[suite] ||= {}
      #@test_results[suite][test.to_sym] = record

      case_change = false

      if @previous_case != result.test_case
        case_change = true  
        before_case(result.test_case)
      end

      #before_test(result)
      case result.type
      when :skip
        test_skip(result)
      when :pass
        test_pass(result)
      when :fail
        test_fail(result)
      when :err
        test_err(result)
      end
      after_test(result)

      if case_change
        after_case(result.test_case)
      end

      @previous_case = result.test_case
    end

    #
    # Minitest's finalization hook.
    #
    def report
      super

      uncapture_io

      after_suite()
    end

    #
    # Intermediary Callbacks
    #

    #
    def before_suite(test_cases)
      @suite_start_time = Time.now
      count_tests!(test_cases)
      tapout_before_suite()
    end

    def after_suite() #(test_cases)
      tapout_after_suite()
    end

    def before_case(test_case)
      @case_start_time = Time.now
      tapout_before_case(test_case)
    end

    def after_case(test_case)
      tapout_after_case(test_case)
    end

    def before_test(result)
      @test_start_time = Time.now
      tapout_before_test(result)
    end

    def after_test(result)
      tapout_after_test(result)
    end

    def test_skip(result)
      tapout_test_skip(result)
    end

    def test_pass(result)
      tapout_test_pass(result)
    end

    def test_fail(result)
      tapout_test_failure(result)
    end

    def test_err(result)
      tapout_test_error(result)
    end

=begin
    def _run_suites(suites, type)
      #output.puts "# Run options: #{@help}"

      @suites_start_time = Time.now
      count_tests!(suites, type)
      trigger_callback(:before_suites, suites, type)
      super(suites, type)
    ensure
      trigger_callback(:after_suites, suites, type)
    end

    def _run_suite(suite, type)
      # The only reason this is here is b/c MiniTest wil try to run
      # base classes like `MiniTest::Spec`. So to prevent that,
      # if there are no tests to run, we don't bother to process
      # the "suite" at all.
      @_suite_tests = suite.send("#{type}_methods")
      return [0,0] if @_suite_tests.empty?

      begin
        @suite_start_time = Time.now
        trigger_callback(:before_suite, suite)

        super_result = nil
        @_stdout, @_stderr = capture_io do
          super_result = super(suite, type)
        end
        super_result
      ensure
        trigger_callback(:after_suite, suite)
      end
    end

    def before_test(suite, test)
      @test_start_time = Time.now
      trigger_callback(:before_test, suite, test)
    end

    def after_test(suite, test)
      #runners = @test_recorder[suite, test.to_sym]
      #records = @test_results[suite][test.to_sym]
      record = @test_results[suite][test.to_sym]

      #records.each do |record|
      #  trigger_callback(record.result, suite, test.to_sym, record)
      #end

      trigger_callback(record.result, suite, test.to_sym, record)

      #trigger_callback(:after_test, suite, test.to_sym)
    end
=end

    # Stub out the three IO methods used by the built-in reporter.
    def p(*args)
      args.each{ |a| io.print(a.inspect); puts }
    end

    def puts(*args)
      io.puts(*args)
    end

    def print(*args)
      io.print(*args)
    end

    #def status(io = output); end

  private

    #    
    def filtered_tests(test_case) #suite, type
      filter = options[:filter] || '/./'
      filter = Regexp.new($1) if filter =~ /\/(.*)\//
      test_case.runnable_methods.grep(filter)
    end

=begin
    #
    def add_test_result(suite, test, test_runner)
      self.report[suite] ||= {}
      self.report[suite][test.to_sym] = test_runner
      
      self.assertion_count += test_runner.assertions
      
      case test_runner.result
      when :skip then self.skips += 1
      when :failure then self.failures += 1
      when :error then self.errors += 1
      end
    end
=end

    def count_tests!(test_cases)
      filter = options[:filter] || '/./'
      filter = Regexp.new $1 if filter =~ /\/(.*)\//

      @test_count = test_cases.inject(0) do |acc, test_case|
        acc + test_case.runnable_methods.grep(filter).length
      end
    end

    #
    # Tapout Records
    #

    #
    def tapout_before_suite()
      doc = {
        'type'  => 'suite',
        'start' => self.suite_start_time.strftime('%Y-%m-%d %H:%M:%S'),
        'count' => self.test_count,
        'seed'  => self.options[:seed],
        'rev'   => REVISION
      }
      return doc
    end

    #
    def tapout_after_suite()
      doc = {
        'type' => 'final',
        'time' => Time.now - self.suite_start_time,
        'counts' => {
          'total' => self.test_count,
          'pass'  => self.test_count - self.failures - self.errors - self.skips,
          'fail'  => self.failures,
          'error' => self.errors,
          'omit'  => self.skips,
          'todo'  => 0  # TODO: does minitest support pending tests?
        }
      }
      return doc
    end

    #
    def tapout_before_case(test_case)
      doc = {
        'type'    => 'case',
        'subtype' => '',
        'label'   => "#{test_case}",
        'level'   => 0
      }

      record_stdcom(doc)

      return doc
    end

    #
    def tapout_after_case(test_case)
    end

    #
    def tapout_before_test(result)
    end

    #
    def tapout_after_test(result)
    end

    # TAP record for pass.
    #
    # Returns [Hash].
    def tapout_test_pass(result) #suite, test, test_runner
      doc = {
        'type'        => 'test',
        'subtype'     => '',
        'status'      => 'pass',
        #'setup': foo instance
        'label'       => "#{result.label}",
        #'expected' => 2
        #'returned' => 2
        #'file' => 'test/test_foo.rb'
        #'line': 45
        #'source': ok 1, 2
        #'snippet':
        #  - 44: ok 0,0
        #  - 45: ok 1,2
        #  - 46: ok 2,4
        #'coverage':
        #  file: lib/foo.rb
        #  line: 11..13
        #  code: Foo#*
        'time' => Time.now - self.suite_start_time
      }

      record_stdcom(doc)

      #stdout, stderr = @_stdout, @_stderr
      #doc['stdout'] = stdout unless stdout.empty?
      #doc['stderr'] = stderr unless stderr.empty?

      return doc
    end

    # TAP record for skip.
    #
    # Returns [Hash].
    def tapout_test_skip(result) #suite, test, test_runner
      e = result.exception
      e_file, e_line = location(result.exception)
      r_file = e_file.sub(Dir.pwd+'/', '')

      doc = {
        'type'        => 'test',
        'subtype'     => '',
        'status'      => 'skip',
        'label'       => "#{result.label}",
        #'setup' => "foo instance",
        #'expected' => 2,
        #'returned' => 1,
        #'file' => test/test_foo.rb
        #'line' => 45
        #'source' => ok 1, 2
        #'snippet' =>
        #  - 44: ok 0,0
        #  - 45: ok 1,2
        #  - 46: ok 2,4
        #'coverage' =>
        #  'file' => lib/foo.rb
        #  'line' => 11..13
        #  'code' => Foo#*
        'exception' => {
          'message'   => clean_message(e.message),
          'class'     => e.class.name,
          'file'      => r_file,
          'line'      => e_line,
          'source'    => source(e_file)[e_line-1].strip,
          'snippet'   => code_snippet(e_file, e_line),
          'backtrace' => filter_backtrace(e.backtrace)
        },
        'time' => Time.now - self.suite_start_time
      }
      return doc
    end

    # TAP record for failure.
    #
    # Returns [Hash].
    def tapout_test_failure(result)
      e = result.exception
      e_file, e_line = location(result.exception)
      r_file = e_file.sub(Dir.pwd+'/', '')

      doc = {
        'type'        => 'test',
        'subtype'     => '',
        'status'      => 'fail',
        'label'       => "#{result.label}",
        #'setup' => "foo instance",
        #'expected' => 2,
        #'returned' => 1,
        #'file' => test/test_foo.rb
        #'line' => 45
        #'source' => ok 1, 2
        #'snippet' =>
        #  - 44: ok 0,0
        #  - 45: ok 1,2
        #  - 46: ok 2,4
        #'coverage' =>
        #  'file' => lib/foo.rb
        #  'line' => 11..13
        #  'code' => Foo#*
        'exception' => {
          'message'   => clean_message(e.message),  
          'class'     => e.class.name,
          'file'      => r_file,
          'line'      => e_line,
          'source'    => source(e_file)[e_line-1].strip,
          'snippet'   => code_snippet(e_file, e_line),
          'backtrace' => filter_backtrace(e.backtrace)
        },
        'time' => Time.now - self.suite_start_time   # result.time
      }

      record_stdcom(doc)

      #stdout, stderr = @_stdout, @_stderr
      #doc['stdout'] = stdout unless stdout.empty?
      #doc['stderr'] = stderr unless stderr.empty?

      return doc
    end

    # TAP record for error.
    #
    # Returns [Hash].
    def tapout_test_error(result)
      e = result.exception
      e_file, e_line = location(e)
      r_file = e_file.sub(Dir.pwd+'/', '')

      doc = {
        'type'        => 'test',
        'subtype'     => '',
        'status'      => 'error',
        'label'       => "#{result.label}",
        #'setup' => "foo instance",
        #'expected' => 2,
        #'returned' => 1,
        #'file' => test/test_foo.rb
        #'line' => 45
        #'source' => ok 1, 2
        #'snippet' =>
        #  - 44: ok 0,0
        #  - 45: ok 1,2
        #  - 46: ok 2,4
        #'coverage' =>
        #  'file' => lib/foo.rb
        #  'line' => 11..13
        #  'code' => Foo#*
        'exception' => {
          'message'   => clean_message(e.error.message),
          'class'     => e.error.class.name,
          'file'      => r_file,
          'line'      => e_line,
          'source'    => source(e_file)[e_line-1].strip,
          'snippet'   => code_snippet(e_file, e_line),
          'backtrace' => filter_backtrace(e.backtrace)
        },
        'time' => Time.now - self.suite_start_time  # result.time
      }

      record_stdcom(doc)

      #stdout, stderr = @_stdout, @_stderr
      #doc['stdout'] = stdout unless stdout.empty?
      #doc['stderr'] = stderr unless stderr.empty?

      return doc
    end

    # ---------------------------------------------------------------------

    #
    #
    #
    def record_stdcom(doc)
      begin
        doc['stdout'] = $stdout.string unless $stdout.length == 0 #empty?
        doc['stderr'] = $stderr.string unless $stderr.length == 0 #empty?
        $stdout.close; $stderr.close
        $stdout, $stderr = StringIO.new, StringIO.new
      #end
      rescue => err
        uncapture_io
        raise err
      end
    end

    #
    #def filter_backtrace(backtrace)
    #  trace = backtrace
    #  trace = clean_backtrace(trace)
    #  trace = MiniTest::filter_backtrace(trace)
    #  trace
    #end

    # Clean the backtrace of any reference to test framework itself.
    def filter_backtrace(backtrace)
      ## remove backtraces that match any pattern in IGNORE_CALLERS
      trace = backtrace.reject{|b| IGNORE_CALLERS.any?{|i| i=~b}}
      ## remove `:in ...` portion of backtraces
      trace = trace.map do |bt| 
        i = bt.index(':in')
        i ? bt[0...i] :  bt
      end
      ## now apply MiniTest's own filter (note: doesn't work if done first, why?)
      trace = Minitest::filter_backtrace(trace)
      ## if the backtrace is empty now then revert to the original
      trace = backtrace if trace.empty?
      ## simplify paths to be relative to current workding diectory
      trace = trace.map{ |bt| bt.sub(Dir.pwd+File::SEPARATOR,'') }
      return trace
    end

    # Returns a String of source code.
    def code_snippet(file, line)
      s = []
      if File.file?(file)
        source = source(file)
        radius = 2 # TODO: make customizable (number of surrounding lines to show)
        region = [line - radius, 1].max ..
                 [line + radius, source.length].min

        s = region.map do |n|
          {n => source[n-1].chomp}
        end
      end
      return s
    end

    # Cache source file text. This is only used if the TAP-Y stream
    # doesn not provide a snippet and the test file is locatable.
    def source(file)
      @_source_cache[file] ||= (
        File.readlines(file)
      )
    end

    # Parse source location from caller, caller[0] or an Exception object.
    def parse_source_location(caller)
      case caller
      when Exception
        trace  = caller.backtrace.reject{ |bt| bt =~ INTERNALS }
        caller = trace.first
      when Array
        caller = caller.first
      end
      caller =~ /(.+?):(\d+(?=:|\z))/ or return ""
      source_file, source_line = $1, $2.to_i
      return source_file, source_line
    end

    # Get location of exception.
    def location e # :nodoc:
      last_before_assertion = ""
      e.backtrace.reverse_each do |s|
        break if s =~ /in .(assert|refute|flunk|pass|fail|raise|must|wont)/
        last_before_assertion = s
      end
      file, line = last_before_assertion.sub(/:in .*$/, '').split(':')
      line = line.to_i if line
      return file, line
    end

    #
    def clean_message(message)
      message.strip #.gsub(/\s*\n\s*/, "\n")
    end

    #
    #def capture_io
    #  ostdout, ostderr = $stdout, $stderr
    #  cstdout, cstderr = StringIO.new, StringIO.new
    #  $stdout, $stderr = cstdout, cstderr
    #
    #  yield
    #
    #  return cstdout.string.chomp("\n"), cstderr.string.chomp("\n")
    #ensure
    #  $stdout = ostdout
    #  $stderr = ostderr
    #end

    #
    def capture_io
      @_stdout, @_stderr = $stdout, $stderr
      $stdout, $stderr = StringIO.new, StringIO.new
    end

    #
    def uncapture_io
      $stdout, $stderr = @_stdout, @_stderr
    end

  end

  #
  # TestResult delegtes to Minitest's own test result object.
  #
  class TestResult
    # Create new TestResult instance.
    #
    # result - MiniTest's test result object.
    #
    def initialize(result)
      @result = result
    end

    def test_case
      @result.class
    end
    alias :testcase :test_case

    # Name of the test.
    def name
      @result.name
    end
    alias :test :name

    #
    def label
      if spec?
        name.sub(/^test_\d+_/, '').gsub('_', ' ')
      else
        name
      end
    end

    # Is this a Minitest::Spec?
    #
    # Returns [Boolean].
    def spec?
      @is_spec ||= (
        Minitest.const_defined?(:Spec) && @result.class < Minitest::Spec
        #@result.class.methods.include?(:it) || @result.class.methods.include?('it')
      )
    end

    # Number of assertions made by test.
    #
    # Returns [Integer].
    def assertions
      @result.assertions
    end

    #
    def time
      @result.time
    end

    #
    def exception
      @result.failure
    end

    # Result type.
    def type
      case exception
      when UnexpectedError
        :err
      when Skip
        :skip
      when Assertion
        :fail
      when nil 
        :pass
      else 
        :err
      end
    end
  end

=begin
  # Runner for individual MiniTest tests.
  # 
  # You *should not* create instances of this class directly. Instances of
  # {SuiteRunner} will create these and send them to the reporters.
  # 
  # Based upon Ryan Davis of Seattle.rb's MiniTest (MIT License).
  # 
  # @see https://github.com/seattlerb/minitest MiniTest
  class TestRunner
    attr_reader :suite, :test, :assertions, :result, :exception
    attr_reader :stdout, :stderr

    def initialize(suite, test)
      @suite = suite
      @test = test
      @assertions = 0
    end
    
    def run
      suite_instance = suite.new(test)
      test_result = nil
      @stdout, @stderr = capture_io do
        test_result = suite_instance.run(self)
      end
      @result, @exception = fix_result(test_result)
      @assertions = suite_instance._assertions
    end

    def puke(suite, test, exception)
      case exception
      when MiniTest::Skip then [:skip, exception]
      when MiniTest::Assertion then [:failure, exception]
      else [:error, exception]
      end
    end

    def record(suite, method, assertions, time, error)
    end

  private
    
    #
    def fix_result(result)
      result == '.' ? [:pass, nil] : result
    end

    #
    def capture_io
      ostdout, ostderr = $stdout, $stderr
      cstdout, cstderr = StringIO.new, StringIO.new
      $stdout, $stderr = cstdout, cstderr

      yield

      return cstdout.string.chomp("\n"), cstderr.string.chomp("\n")
    ensure
      $stdout = ostdout
      $stderr = ostderr
    end
  end
=end

=begin
  ##
  # Around advice.
  #
  module AroundTestHooks
    def self.before_test(instance)
      if before_test = (MiniTest::Unit.runner.method(:before_test) rescue nil)
        before_test.call(instance.class, instance.__name__)
      end
    end

    def self.after_test(instance)
      # MiniTest < 4.1.0 sends #record after all teardown hooks, so don't call
      # #after_test here.
      if MiniTest::Unit::VERSION > "4.1.0"
        if after_test = (MiniTest::Unit.runner.method(:after_test) rescue nil)
          after_test.call(instance.class, instance.__name__)
        end
      end
    end

    def before_setup
      AroundTestHooks.before_test(self)
      super
    end

    def after_teardown
      super
      AroundTestHooks.after_test(self)
    end
  end

  class Unit::TestCase
    include AroundTestHooks
  end
=end

  ##
  # TAP-Y adapater.
  #
  class TapY < Minitap
    def initialize(options={})
      require 'yaml' unless respond_to?(:to_yaml)
      super(options)
    end

    def tapout_before_suite()
      wp super().to_yaml
    end
    def tapout_before_case(test_case)
      wp super(test_case).to_yaml
    end
    def tapout_test_pass(result)
      wp super(result).to_yaml
    end
    def tapout_test_skip(result)
      wp super(result).to_yaml
    end
    def tapout_test_failure(result)
      wp super(result).to_yaml
    end
    def tapout_test_error(result)
      wp super(result).to_yaml
    end
    def tapout_after_suite()
      wp super().to_yaml
      wp "..."
    end

    def wp(str)
      io.puts(str)
    end
  end

  ##
  # TAP-J adapater.
  #
  class TapJ < Minitap
    def initialize(options={})
      require 'json' unless respond_to?(:to_json)
      super(options)
    end

    def tapout_before_suite()
      wp super().to_json
    end
    def tapout_before_case(test_case)
      wp super(test_case).to_json
    end
    def tapout_test_pass(result)
      wp super(result).to_json
    end
    def tapout_test_skip(result)
      wp super(result).to_json
    end
    def tapout_test_failure(result)
      wp super(result).to_json
    end
    def tapout_test_error(result)
      wp super(result).to_json
    end
    def tapout_after_suite()
      wp super().to_json
    end

    def wp(str)
      io.puts(str)
    end
  end

end
