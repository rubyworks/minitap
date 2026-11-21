require 'minitest'
require 'stringio'

module Minitap

  # Base class of the TAP-Y and TAP-J reporters. It turns Minitest's
  # results into the records of a TAP-Y/J stream; the subclasses write
  # them out.
  #
  # While tests run, `$stdout` and `$stderr` are captured, so that
  # what a test prints becomes part of its record instead of breaking
  # the stream.
  class Reporter < Minitest::StatisticsReporter

    # TAP-Y/J revision.
    REVISION = 4

    # Number of lines of source to show on each side of a failure.
    SNIPPET_RADIUS = 2

    # Where Minitap's own code lives, to keep it out of backtraces.
    LIB_DIRECTORY = File.expand_path('..', __dir__) + File::SEPARATOR

    def initialize(io = $stdout, options = {})
      super
      # Tapout reads from a pipe, so nothing should wait in a buffer.
      io.sync = true if io.respond_to?(:sync=)
      @source_cache = {}
      @current_case = nil
    end

    # Minitest calls this just before the tests run.
    def start
      super
      @suite_start = Time.now
      capture_io
      emit suite_record
    end

    # Minitest calls this with the result of each test.
    def record(result)
      super
      test_case = case_name(result)
      if test_case != @current_case
        @current_case = test_case
        emit case_record(test_case)
      end
      emit test_record(result)
    end

    # Minitest calls this when all tests have run.
    def report
      super
      release_io
      emit final_record
      finish
    end

  private

    # Write a record to the stream. Subclasses define this.
    def emit(record)
      raise NotImplementedError
    end

    # Write whatever ends the stream.
    def finish
    end

    #
    def suite_record
      {
        'type'  => 'suite',
        'start' => @suite_start.strftime('%Y-%m-%d %H:%M:%S'),
        'count' => test_count,
        'seed'  => options[:seed],
        'rev'   => REVISION
      }
    end

    #
    def case_record(test_case)
      {
        'type'  => 'case',
        'label' => test_case.to_s,
        'level' => 0
      }
    end

    #
    def test_record(result)
      failure = result.failure

      record = {
        'type'   => 'test',
        'status' => status(failure),
        'label'  => label(result)
      }
      record['exception'] = exception_record(failure) if failure

      stdout, stderr = captured_output
      record['stdout'] = stdout unless stdout.empty?
      record['stderr'] = stderr unless stderr.empty?

      record['time'] = Time.now - @suite_start
      record
    end

    #
    def final_record
      {
        'type'   => 'final',
        'time'   => Time.now - @suite_start,
        'counts' => {
          'total' => count,
          'pass'  => count - failures - errors - skips,
          'fail'  => failures,
          'error' => errors,
          'omit'  => skips,
          'todo'  => 0
        }
      }
    end

    # TAP-Y/J calls a skipped test omitted.
    def status(failure)
      case failure
      when nil                        then 'pass'
      when Minitest::UnexpectedError  then 'error'
      when Minitest::Skip             then 'omit'
      else                                 'fail'
      end
    end

    # The name of the test. Minitest::Spec names a test
    # `test_0001_does something`; the label is the part that was written.
    def label(result)
      result.name.to_s.sub(/\Atest_\d{4}_/, '')
    end

    # The name of the class the test belongs to.
    def case_name(result)
      result.respond_to?(:klass) ? result.klass.to_s : result.class.name
    end

    #
    def exception_record(failure)
      error     = actual_error(failure)
      backtrace = clean_backtrace(failure.backtrace || error.backtrace)
      file, line = location(backtrace)

      record = { 'message' => error.message.to_s.strip, 'class' => error.class.name }

      if file
        record['file'] = file
        record['line'] = line
        if lines = source(file)
          record['source']  = lines[line - 1].to_s.strip
          record['snippet'] = snippet(lines, line)
        end
      end

      record['backtrace'] = backtrace
      record
    end

    # Minitest wraps an error raised by a test in an UnexpectedError.
    def actual_error(failure)
      return failure unless Minitest::UnexpectedError === failure
      failure.respond_to?(:error) ? failure.error : failure.exception
    end

    # The backtrace without the test framework, without the method
    # names, and with paths relative to the working directory.
    def clean_backtrace(backtrace)
      trace = Minitest.filter_backtrace(Array(backtrace))
      trace = trace.reject { |line| line.start_with?(LIB_DIRECTORY) }
      trace.map do |line|
        line.sub(/:in .*\z/m, '').sub(Dir.pwd + File::SEPARATOR, '')
      end
    end

    # File and line number of the first line of a backtrace.
    def location(backtrace)
      md = /\A(.+?):(\d+)\z/.match(backtrace.first.to_s)
      md ? [md[1], md[2].to_i] : [nil, nil]
    end

    # The lines of a source file, or nil if it can't be read.
    def source(file)
      return @source_cache[file] if @source_cache.key?(file)
      @source_cache[file] = File.file?(file) ? File.readlines(file) : nil
    end

    # The lines around a line of source, as a list of number => text.
    def snippet(lines, line)
      first = [line - SNIPPET_RADIUS, 1].max
      last  = [line + SNIPPET_RADIUS, lines.size].min
      (first..last).map { |n| { n => lines[n - 1].chomp } }
    end

    # How many tests are about to run.
    #
    # Asking a class for its tests shuffles them, which draws on Ruby's
    # random numbers. So they are seeded again afterwards, and the tests
    # run in the order they would have without Minitap.
    def test_count
      total = Minitest::Runnable.runnables.inject(0) do |sum, runnable|
        sum + selected_methods(runnable).size
      end
      srand options[:seed] if options[:seed]
      total
    end

    # The tests of a class that Minitest's name options select. The
    # option is `:include` in Minitest 6 and `:filter` before.
    def selected_methods(runnable)
      methods = runnable.runnable_methods
      wanted  = name_pattern(options[:include] || options[:filter])
      spurned = name_pattern(options[:exclude])
      methods = methods.select { |m| wanted === m  || wanted === "#{runnable}##{m}" } if wanted
      methods = methods.reject { |m| spurned === m || spurned === "#{runnable}##{m}" } if spurned
      methods
    rescue NotImplementedError
      []
    end

    # A name option written `/like this/` is a regular expression.
    def name_pattern(pattern)
      String === pattern && pattern =~ %r{/(.*)/} ? Regexp.new($1) : pattern
    end

    #
    def capture_io
      @real_stdout, @real_stderr = $stdout, $stderr
      @stdout, @stderr = StringIO.new, StringIO.new
      $stdout, $stderr = @stdout, @stderr
    end

    #
    def release_io
      $stdout = @real_stdout if $stdout.equal?(@stdout)
      $stderr = @real_stderr if $stderr.equal?(@stderr)
    end

    # What has been printed since the last record, as two strings.
    def captured_output
      [@stdout, @stderr].map do |capture|
        text = capture.string.dup
        capture.truncate(0)
        capture.rewind
        text
      end
    end

  end

  # Reports in TAP-Y, a stream of YAML documents.
  class TapY < Reporter

    def initialize(io = $stdout, options = {})
      require 'yaml'
      super
    end

  private

    def emit(record)
      io.puts record.to_yaml
    end

    def finish
      io.puts '...'
    end

  end

  # Reports in TAP-J, a JSON document on each line.
  class TapJ < Reporter

    def initialize(io = $stdout, options = {})
      require 'json'
      super
    end

  private

    def emit(record)
      io.puts JSON.generate(record)
    end

  end

end
