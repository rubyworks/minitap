require 'tapout'

When 'Given a Minitest (((Test|Spec)))' do |type, text|
  @test = text
end

When 'Running it with the (((.*?))) format' do |type|
  File.open('test.rb', 'w'){ |f| 
    f << test_helper(type) + "\n\n" + @test 
  }

  if type == 'TAP-Y' then
    @out = `ruby -I../../lib test.rb - --tapy`
  else
    @out = `ruby -I../../lib test.rb - --tapj`
  end

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

# TODO: How to offer option to select the format via code?

def test_helper(type)
  if type == 'TAP-Y' then
    %Q{
      # (This is the old MiniTest 4.0 way.)
      #require 'minitap'
      #MiniTest::Unit.runner = MiniTest::TapY.new
      require 'minitest/autorun'
    }
  else
    %Q{
      #require 'minitap'
      #MiniTest::Unit.runner = MiniTest::TapJ.new
      require 'minitest/autorun'
    }
  end
end

