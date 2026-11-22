require_relative 'lib/minitap/version'

Gem::Specification.new do |s|
  s.name        = 'minitap'
  s.version     = Minitap::VERSION
  s.summary     = 'TAP-Y/J reporters for Minitest'
  s.description = 'Minitap is a Minitest plugin that reports test results in TAP-Y ' \
                  'or TAP-J, for Tapout to render in any of its formats.'

  s.authors  = ['Trans']
  s.email    = ['transfire@gmail.com']
  s.homepage = 'https://github.com/rubyworks/minitap'
  s.license  = 'BSD-2-Clause'

  s.metadata = {
    'homepage_uri'      => s.homepage,
    'source_code_uri'   => 'https://github.com/rubyworks/minitap',
    'bug_tracker_uri'   => 'https://github.com/rubyworks/minitap/issues',
    'changelog_uri'     => 'https://github.com/rubyworks/minitap/blob/master/HISTORY.md',
    'documentation_uri' => 'https://rubydoc.info/gems/minitap'
  }

  s.required_ruby_version = '>= 2.7'

  s.files = Dir[
    'lib/**/*.rb', 'demo/**/*',
    '.yardopts', 'README.md', 'HISTORY.md', 'LICENSE.txt', 'NOTICE.md'
  ]
  s.require_paths    = ['lib']
  s.extra_rdoc_files = ['HISTORY.md', 'README.md', 'LICENSE.txt', 'NOTICE.md']

  s.add_dependency 'minitest', '>= 5.11', '< 7'
  s.add_dependency 'tapout', '>= 0.5'
  s.add_dependency 'json'

  s.add_development_dependency 'rake', '>= 13'
  s.add_development_dependency 'qed', '>= 2.9'
  s.add_development_dependency 'ae', '>= 1.8'
end
