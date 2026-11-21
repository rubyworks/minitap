# Minitap

[Documentation](https://rubydoc.info/gems/minitap) |
[Report Issue](https://github.com/rubyworks/minitap/issues) |
[Source Code](https://github.com/rubyworks/minitap)

[![CI](https://github.com/rubyworks/minitap/actions/workflows/ci.yml/badge.svg)](https://github.com/rubyworks/minitap/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/minitap.svg)](https://badge.fury.io/rb/minitap)


# About

Minitap is a [Minitest](https://github.com/minitest/minitest) plugin that
reports test results in TAP-Y or TAP-J. Those are the formats that
[Tapout](https://github.com/rubyworks/tapout) reads, so with Minitap a
Minitest suite can be shown in any of Tapout's report formats.

    $ ruby -Ilib test/some_test.rb --tapy | tapout progress

Minitap works with Minitest 5.11 and newer, including Minitest 6, on
Ruby 2.7 and newer.


# Installation

    $ gem install minitap

Or in a Gemfile:

    gem 'minitap'

Tapout is installed along with it.


# Usage

Load Minitap in your test helper, after Minitest:

    require 'minitest/autorun'
    require 'minitap'

That adds two options to the test command line, `--tapy` and `--tapj`.
Without one of them Minitest reports as usual.

    $ ruby -Ilib test/some_test.rb --tapy

The output is a TAP-Y stream, which isn't meant to be read as it is.
Pipe it to `tapout`, with the name of the report you want:

    $ ruby -Ilib test/some_test.rb --tapy | tapout progress

`tapout --help` lists the reports.

## With Rake

Rake's `TestTask` and Minitest's own `Minitest::TestTask` pass the
`TESTOPTS` variable on to Minitest:

    $ rake test TESTOPTS=--tapy | tapout progress

Rake's `-q` option keeps Rake's own output out of the stream.

## In code

To always report in TAP-Y or TAP-J, say so in the test helper:

    require 'minitest/autorun'
    require 'minitap'

    Minitap.tapy!    # or Minitap.tapj!

An option on the command line still takes precedence. `Minitap.format = :tapj`
does the same as `Minitap.tapj!`, which is handy with a variable:

    Minitap.format = ENV['TAP_FORMAT'] if ENV['TAP_FORMAT']

As a shorthand, `require 'minitap/autorun'` requires `minitest/autorun`
and chooses TAP-Y:

    require 'minitap/autorun'

## Loading the plugin

Minitap is an ordinary Minitest plugin, so Minitest's own ways of
loading one work as well as `require 'minitap'`:

    Minitest.load :minitap

Minitest 5 loads every installed plugin by itself, so there the options
are available without anything in the test helper. Minitest 6 no longer
does that, and one of the lines above is needed.

## What is reported

* Each test class is a case, and each test a test, labelled by name. A
  spec is labelled as it was written.
* A failure or error comes with its message, the file and line in your
  code, the lines of source around it, and a backtrace without Minitest
  in it.
* A skipped test is reported as omitted, with the reason.
* What a test prints to `$stdout` and `$stderr` is captured and reported
  with the test, since it would otherwise break the stream.


# Upgrading from 0.5

Version 0.6 uses Minitest's plugin system only, and no longer needs the
`minitest-reporter-api` gem.

* `Minitest.reporter = Minitap::TapY` no longer does anything. Use
  `Minitap.tapy!` instead.
* The reporters are `Minitap::TapY` and `Minitap::TapJ`. They are no
  longer also defined as `Minitest::TapY` and `Minitest::TapJ`.
* Skipped tests have the status `omit`, as TAP-Y/J specifies. They used
  to have the status `skip`.

For Minitest 4 and older, use Minitap 0.4.


# Using Pry & Other Tools

Because Tapout reads Minitest's output through a pipe, anything in the
stream that isn't TAP-Y/J may make it halt. A debugger needs the
terminal, though. For that there is a *pause code* (`16.chr`), which
tells `tapout` to stop reading test results and pass everything
straight through, and a *resume code* (`23.chr`), which starts it
reading again.

With `binding.pry`, for example:

    require 'tapout/utility'
    tapout.pause{ binding.pry }

Or, more convenient still:

    require 'tapout/utility'
    tapout.pry(binding)

Which amounts to:

    STDOUT.puts 16.chr
    binding.pry
    STDOUT.puts 23.chr


# Copying

Copyright (c) 2011 Rubyworks

Made available under the terms of the *BSD-2-Clause* license.

Portions of this program were drawn from Alexander Kern's
MiniTest Reporter (c) 2011 Alexander Kern. Thanks Alexander
for making my endeavor a little bit easier.

See LICENSE.txt and NOTICE.md for copyright and licensing details.
