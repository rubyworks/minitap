require 'tapout'

When 'Given a Minitest (((Test|Spec)))' do |type, text|
  @test = text
end

When 'Running it with the (((.*?))) format' do |type|
  File.open('test.rb', 'w') { |f| 
    f << "\n" + test_helper(type) + "\n\n" + @test
  }

  @out = test_command(type)

  #@stream = YAML.load_documents(@out)  # b/c of bug in Ruby 1.8
  @stream = (
    s = []
    YAML.load_documents(@out){ |d| s << d }
    s
  )
end

#When '(((\w+))) reporter should run without error' do |format|
#  $stdin  = StringIO.new(@tapy)
#  $stdout = StringIO.new(out = '')
#
#  TapOut.cli(format)
#end

def test_command(type)
  #return test_command_4 if ENV['minitest'] == "4"

  if type == 'TAP-Y'
    `ruby -I../../lib test.rb - --tapy`
  else
    `ruby -I../../lib test.rb - --tapj`
  end
end

# TODO: Is there a way to offer option to select the format via code?
def test_helper(type)
  #return test_helper_4(type) if ENV['minitest'] == "4"

  "require 'minitest/autorun'"
end

=begin
def test_command_4
  `ruby -I../../lib test.rb`
end

# For Minitest v4.
def test_helper_4(type)
  if type == 'TAP-Y' then
    %Q{
      require 'minitap'
      MiniTest::Unit.runner = MiniTest::TapY.new
      require 'minitest/autorun'
    }
  else
    %Q{
      require 'minitap'
      MiniTest::Unit.runner = MiniTest::TapJ.new
      require 'minitest/autorun'
    }
  end
end
=end
