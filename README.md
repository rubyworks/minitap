# Minitap

[Website](http://rubyworks.github.com/minitap) |
[Documentation](http://rubydoc.info/gems/minitap/frames) |
[Report Issue](http://github.com/rubyworks/minitap/issues) |
[Source Code](http://github.com/rubyworks/minitap)

[![Build Status](https://travis-ci.org/rubyworks/minitap.png)](https://travis-ci.org/rubyworks/minitap)
[![Gem Version](https://badge.fury.io/rb/minitap.png)](http://badge.fury.io/rb/minitap) &nbsp; &nbsp;
[![Flattr Me](http://api.flattr.com/button/flattr-badge-large.png)](http://flattr.com/thing/324911/Rubyworks-Ruby-Development-Fund)


# About

The MiniTap project provides a TAP-Y and TAP-J output reporters for
the MiniTest test framework --the test framework that comes standard
with Ruby 1.9+.

See [TAPOUT](http://rubyworks.github.com/tapout) for more information about
TAP-Y/J formats.


# Usage

## Minitest 5

Minitest 5 has a new report system and plug-in API. Minitap takes advantage
of this new API to allow the TAP-Y or TAP-J formats to be selected via command-line
options as an alternative to setting the format in test helper scripts.

### Via Command Line

To use simply add `--tapy` or `--tapj` after an isolated `-` separator on the
ruby test command invocation, e.g.

    $ ruby -Ilib test/runner.rb - --tapy

In your test helper scripts be sure you have the standard Minitest line:

    require 'minitest/autorun'

And remove any old `MiniTest::Unit.runner=` assignments if you are migrating 
from v4.

Now to do something interesting with the TAP-Y/J output, you will probably want
to install `tapout`:

    $ gem install tapout

Then pipe the output to the `tapout` command, e.g.

    $ ruby test/some_test.rb - --tapy | tapout progressbar

### Via Helper Script

To use via test helper script, require the `minitap` library after `minitest/autorun`
and assign `Minitest.reporter` to the Minitap reporter to be used.

    require "minitest/autorun"
    require "minitap"

    Minitest.reporter = Minitap::TapY
    
Then pipe the output to the `tapout` command, e.g.

    $ ruby -Ilib test/runner.rb | tapout progrssbar

Or using Rake:

    $ rake test | tapout progressbar

You may need the `-q` option for Rake to supress extraneous output.


## MiniTest 4

If you are still using MiniTest 4.x you will need to use Minitap version 4.x
as well. In your dependencies be sure to specify this version. For example in 
your Gemfile:

    gem "minitap", "~> 0.4.0"

For Minitest 4 and and older, custom report formats are set by assigning
the `MiniTest::Unit.runner` to an instance of a custom runner class. 
In our case we want to set it to an instance of `MiniTest::TapY` or `MiniTest::TapJ`.
So in your project's test helper script add, e.g.

    require 'minitap'
    MiniTest::Unit.runner = MiniTest::TapY.new

Now you may want to set this up so it is selectable. In which case use an
environment variable.

    MiniTest::Unit.runner = \
      case ENV['rpt']
      when 'tapy'
        MiniTest::TapY.new
      when 'tapj'
        MiniTest::TapJ.new
      end

Then you can do, e.g.

    $ rpt=tapy ruby test/some_test.rb

Now to do something interesting with the TAP-Y/J output, you will probably want
to install `tapout`:

    $ gem install tapout

Then pipe the output to the `tapout` command, e.g.

    $ rpt=tapy ruby test/some_test.rb | tapout progressbar


# Using Pry & Other Tools

Becuase Tapout communicates with Minitest via a shell pipe it is improtant
to keep in mind that any non TAP-Y/J output that tapout receives might 
force it to halt. To ensure this doesn't occur a *pause code* (`16.chr`) can
be sent over the pipe to instruct the tapout comamnd to stop processing test
results and route `$stdin` directly to `$stdout` instead. A *resume code*
(`23.chr`) can be sent to restart test result processing.

A good example of this is when using `binding.pry` for debugging. To do so
while using tapout:

    require 'tapout/utility'
    tapout.pause{ binding.pry }

Or, even more convenient, specifically for use with pry:

    require 'tapout/utility'
    tapout.pry(binding)

Which is a more covenient way of coding:

    STDOUT.puts 16.chr
    binding.pry
    STDOUT.puts 23.chr


# Copying

Copyright (c) 2011 Rubyworks

Made available under the terms of the *BSD-2-Clause* license.

Portions of this program were drawn from Alexander Kern's
MiniTest Reporter (c) 2011 Alexander Kern. Thanks Alexander
for making my endeavor a little bit easier.

See COPYING.rdoc for copyright and licensing details.

