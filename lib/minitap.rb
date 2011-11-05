# MiniTest adaptor for tapout.

require 'minitest/unit'
require 'minitap/ignore_callers'
require 'stringio'

# Becuase of some wierdness in MiniTest
#debug, $DEBUG = $DEBUG, false
#require 'minitest/unit'
#$DEBUG = debug

module MiniTest

  # Base class for TapY and TapJ runners.
  # 
  # This is a heavily refactored version of the built-in MiniTest runner. It's
  # about the same speed, from what I can tell, but is significantly easier to
  # extend.
  # 
  # Based upon Ryan Davis of Seattle.rb's MiniTest (MIT License).
  # 
  # @see https://github.com/seattlerb/minitest MiniTest
  #
  class MiniTap < ::MiniTest::Unit

    # TAP-Y/J Revision
    REVISION = 3

    # Backtrace patterns to be omitted.
    IGNORE_CALLERS = ::RUBY_IGNORE_CALLERS

    #
    attr_accessor :suite_start_time, :test_start_time, :reporters
    
    # Initialize new MiniTap MiniTest runner.
    def initialize
      self.report = {}
      self.errors = 0
      self.failures = 0
      self.skips = 0
      self.test_count = 0
      self.assertion_count = 0
      self.verbose = false
      self.reporters = []

      @_source_cache = {}
    end

    # Top level driver, controls all output and filtering.
    def _run args = []
      self.options = process_args(args)

      self.class.plugins.each do |plugin|
        send plugin
        break unless report.empty?
      end

      return failures + errors if @test_count > 0 # or return nil...
    rescue Interrupt
      abort 'Interrupted'
    end

    #
    def _run_anything(type)
      self.start_time = Time.now
      
      suites = suites_of_type(type)
      tests = suites.inject({}) do |acc, suite|
        acc[suite] = filtered_tests(suite, type)
        acc
      end
      
      self.test_count = tests.inject(0) { |acc, suite| acc + suite[1].length }
      
      if test_count > 0
        trigger(:before_suites, suites, type)
        
        fix_sync do
          suites.each { |suite| _run_suite(suite, tests[suite]) }
        end
        
        trigger(:after_suites, suites, type)
      end
    end
    
    def _run_suite(suite, tests)
      unless tests.empty?
        begin
          self.suite_start_time = Time.now
          
          trigger(:before_suite, suite)
          suite.startup if suite.respond_to?(:startup)
          
          tests.each { |test| _run_test(suite, test) }
        ensure
          suite.shutdown if suite.respond_to?(:shutdown)
          trigger(:after_suite, suite)
        end
      end
    end
    
    #
    def _run_test(suite, test)
      self.test_start_time = Time.now

      trigger(:before_test, suite, test)
      
      test_runner = TestRunner.new(suite, test)
      test_runner.run
      add_test_result(suite, test, test_runner)
      
      trigger(test_runner.result, suite, test, test_runner)
    end
    
    #
    def trigger(callback, *args)
      send("tapout_#{callback}", *args)
    end

    private

    #    
    def filtered_tests(suite, type)
      filter = options[:filter] || '/./'
      filter = Regexp.new($1) if filter =~ /\/(.*)\//
      suite.send("#{type}_methods").grep(filter)
    end
    
    #
    def suites_of_type(type)
      TestCase.send("#{type}_suites")
    end
    
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

    #
    def fix_sync
      sync = output.respond_to?(:'sync=') # stupid emacs
      old_sync, output.sync = output.sync, true if sync
      yield
      output.sync = old_sync if sync
    end

    #
    def tapout_before_suites(suites, type)
      doc = {
        'type'  => 'suite',
        'start' => self.start_time.strftime('%Y-%m-%d %H:%M:%S'),
        'count' => self.test_count,
        'seed'  => self.options[:seed],
        'rev'   => REVISION
      }
      return doc
    end

    #
    def tapout_after_suites(suites, type)
      doc = {
        'type' => 'final',
        'time' => Time.now - self.test_start_time,
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
    def tapout_before_suite(suite)
      doc = {
        'type'    => 'case',
        'subtype' => '',
        'label'   => "#{suite}",
        'level'   => 0
      }
      return doc
    end

    #
    def tapout_after_suite(suite)
    end

    #
    def tapout_before_test(suite, test)
    end

    #
    def tapout_pass(suite, test, test_runner)
      doc = {
        'type'        => 'test',
        'subtype'     => '',
        'status'      => 'pass',
        #'setup': foo instance
        'label'       => "#{test}",
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
      return doc
    end

    #
    def tapout_skip(suite, test, test_runner)
      e = test_runner.exeception
      e_file, e_line = location(test_runner.exception)
      r_file = e_file.sub(Dir.pwd+'/', '')

      doc = {
        'type'        => 'test',
        'subtype'     => '',
        'status'      => 'skip',
        'label'       => "#{test}",
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

    #
    def tapout_failure(suite, test, test_runner)
      e = test_runner.exception
      e_file, e_line = location(test_runner.exception)
      r_file = e_file.sub(Dir.pwd+'/', '')

      doc = {
        'type'        => 'test',
        'subtype'     => '',
        'status'      => 'fail',
        'label'       => "#{test}",
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

    #
    def tapout_error(suite, test, test_runner)
      e = test_runner.exception
      e_file, e_line = location(test_runner.exception)
      r_file = e_file.sub(Dir.pwd+'/', '')

      doc = {
        'type'        => 'test',
        'subtype'     => '',
        'status'      => 'error',
        'label'       => "#{test}",
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
      trace = MiniTest::filter_backtrace(trace)
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
      returnf source_file, source_line
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

  end

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
    
    def initialize(suite, test)
      @suite = suite
      @test = test
      @assertions = 0
    end
    
    def run
      suite_instance = suite.new(test)
      @result, @exception = fix_result(suite_instance.run(self))
      @assertions = suite_instance._assertions
    end
    
    def puke(suite, test, exception)
      case exception
      when MiniTest::Skip then [:skip, exception]
      when MiniTest::Assertion then [:failure, exception]
      else [:error, exception]
      end
    end
    
    private
    
    def fix_result(result)
      result == '.' ? [:pass, nil] : result
    end
  end

  #
  class TapY < MiniTap
    def initialize
      require 'yaml'
      super
    end
    def tapout_before_suites(suites, type)
      puts super(suites, type).to_yaml
    end
    def tapout_before_suite(suite)
      puts super(suite).to_yaml
    end
    def tapout_pass(suite, test, test_runner)
      puts super(suite, test, test_runner).to_yaml
    end
    def tapout_skip(suite, test, test_runner)
      puts super(suite, test, test_runner).to_yaml
    end
    def tapout_failure(suite, test, test_runner)
      puts super(suite, test, test_runner).to_yaml
    end
    def tapout_error(suite, test, test_runner)
      puts super(suite, test, test_runner).to_yaml
    end
    def tapout_after_suites(suites, type)
      puts super(suites, type).to_yaml
      puts "..."
    end
  end

  #
  class TapJ < MiniTap
    def initializebacktrace
      require 'json'
      super
    end
    def tapout_before_suites(suites, type)
      puts super(suites, type).to_json
    end
    def tapout_before_suite(suite)
      puts super(suite).to_json
    end
    def tapout_pass(suite, test, test_runner)
      puts super(suite, test, test_runner).to_json
    end
    def tapout_skip(suite, test, test_runner)
      puts super(suite, test, test_runner).to_json
    end
    def tapout_failure(suite, test, test_runner)
      puts super(suite, test, test_runner).to_json
    end
    def tapout_error(suite, test, test_runner)
      puts super(suite, test, test_runner).to_json
    end
    def tapout_after_suites(suites, type)
      puts super(suites, type).to_json
    end
  end

end
