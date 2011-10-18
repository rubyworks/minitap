require 'tapout'

When 'Given a MiniTest testcase' do |text|
  @test = text
end

When 'Running it with the (((.*?))) format' do |type|
  File.open('test.rb', 'w'){ |f| f << test_helper(type) + "\n\n" + @test }
  @out    = `ruby test.rb`
  @stream = YAML.load_documents(@out)
end

#When '(((\w+))) reporter should run without error' do |format|
#  $stdin  = StringIO.new(@tapy)
#  $stdout = StringIO.new(out = '')
#
#  TapOut.cli(format)
#end

def test_helper(type)
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
