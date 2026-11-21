require 'minitest'
require 'tmpdir'
require 'open3'
require 'rbconfig'
require 'yaml'
require 'json'

# Each demo writes a test file and runs it in a process of its own,
# the way a test suite is run.

LIB = File.expand_path('../../lib', __dir__)

When 'iven a test file' do |text|
  @source = text
end

# Run the test file with the given command line options. Returns what
# the run wrote to standard output.
def run_tests(*options)
  Dir.mktmpdir('minitap') do |dir|
    File.write(File.join(dir, 'test.rb'), @source)
    command = [RbConfig.ruby, "-I#{LIB}", 'test.rb', *options]
    @stdout, @stderr, @status = Open3.capture3(*command, :chdir => dir)
  end
  @stdout
end

# Run the test file and read its output as a TAP-Y stream.
def run_tapy(*options)
  YAML.load_stream(run_tests(*options))
end

# Run the test file and read its output as a TAP-J stream.
def run_tapj(*options)
  run_tests(*options).lines.map { |line| JSON.parse(line) }
end

# The test records of a stream, by label.
def tests(stream)
  stream.select { |d| d['type'] == 'test' }.to_h { |d| [d['label'], d] }
end

# Pipe a stream through Tapout. Returns what Tapout printed.
def tapout(stream, reporter)
  bin = Gem.bin_path('tapout', 'tapout')
  out, _ = Open3.capture2(RbConfig.ruby, bin, reporter, :stdin_data => stream)
  out
end
