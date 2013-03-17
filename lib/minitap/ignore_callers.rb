ignore = /(lib|bin)#{Regexp.escape(File::SEPARATOR)}minitap/

$RUBY_IGNORE_CALLERS = [] unless defined?($RUBY_IGNORE_CALLERS)
$RUBY_IGNORE_CALLERS << ignore

