# RELEASE HISTORY

## 0.5.3 | 2013-11-20

Small change made to ensure that output i/o is un sync mode.
This prevents test results fro being buffered over the pipe

Changes:

* Add `io.sync = true` *after* Minitest reporter class is initialized.
* Add notes to README about use tapout's pause and resume feature.


## 0.5.2 | 2013-11-18

This release makes it possible to specify reporters in code
(again), and not just on the command line. This makes it easier
to use with other test and build tools such as Rake.

Changes:

* Add support for in code configuration of reporter.
* Use minitest-reporter-api gem to support in code reporter config.


## 0.5.1 | 2013-11-16

This release simply removes all the remaing v4 code that
is no longer needed to work with Minitest 5. This also
fixes an issue Minitap has with working with Rails 4.

Changes:

* Remove all vestigial v4 code.


## 0.5.0 | 2013-11-15

The release adds support for MiniTest 5. Minitest completely 
changes the way custom reporters are handled so this release
includes extensive new code. Note that this version is also
no longer intended for use with Minitest 4 or older. If you
are using Minitest 4, please use Minitap 0.4.x as well.

Changes:

* Add support for Minitest 5.
* Deprecate support for Minitest 4.


## 0.4.1 | 2013-03-18

Minor release improves upon backtrace filtering and makes
the hook extensions more robust when non-minitap runners
are used even though minitap has been requried.

Changes:

* Use $RUBY_IGNORE_CALLERS for backtrace filtering.
* Ensure hook methods exist before using them.
 

## 0.4.0 | 2013-03-17

MiniTap v0.4.0 is a heavy refactorization of the code based on
Alexander Kern's latest MiniTest-Reporters code. (Thank you
Mr. Kern! You made dealing with sorry Minitest code at least
tolerable.) This release also owes gratitiude to Kevin Swope
who's bug report about running on MiniTap with Rails led to
the whole shebang.

Changes:

* Refactored runner to "catch-up" with the ever changing 
  crap that is MiniTest's code.


## 0.3.5 | 2013-01-17

This release adds a #record method to the TestRunner to accomodate 
recent changes to MiniTest.

Changes:

* Add TestRunner#record method.


## 0.3.4 | 2012-05-01

This release simply fixes a misspelling that caused an error
when a test was skipped.

Changes:

* Fix misspelling of the word 'exception'. (#2 Corey O'Connor)


## 0.3.3 | 2012-02-01

This release adds support for the new 'stdout' and 'stderr' fields.
As tests are run $stdout and $stderr are captured and included in
the TAP-Y/J stream. This prevents the structured streams from being
corrupted and provide some nice report options too.

Changes:

* Add support for stdout and stderr capturing.


## 0.3.2 | 2011-11-08

This release add support for the new TAP-Y/J 'class' field, and removes
the class name from the message field. It also fixes a bug that
arose with certain versions of Ruby's YAML.load_documents implementation.

Changes:

* Work around Ruby's YAML.load_documents issue.
* Add dependency for MiniTest.
* Support TAP-Y/J class field.
* Remove class name from message field.


## 0.3.1 | 2011-10-18

This release includes two basic improvements: better backtrace filtering,
and file fields given relative to current working directory instead of
absolute paths. In future maybe this can be configurable, if someone makes
the case that absolute paths are needed.

Changes:

* Improve backtrace filtering.
* Make file fields relative to working directory.


## 0.3.0 | 2011-10-09

Support version 3 of TAP-Y/J spec. This simply entailed renaming
the `tally` document to `final`.

Changes:

* Support revision 3 of TAP-Y/J.


## 0.2.0 | 2011-10-07

This release adjusts how the customer reporter classes
should be used. It's actually a very minor release under 
the hood.

Changes:

* Adjust usage documentation.


## 0.1.0 | 2011-10-06

This is the first release of MiniTap, a TAP-Y/J reporter
for the MiniTest test framework.

Changes:

* First Release Day!
