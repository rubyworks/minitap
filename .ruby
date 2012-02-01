---
source:
- var
authors:
- name: trans
  email: transfire@gmail.com
copyrights:
- holder: Rubyworks
  year: '2011'
  license: BSD-2-Clause
replacements: []
alternatives: []
requirements:
- name: tapout
  version: ! '>= 0.3.0'
- name: minitest
- name: detroit
  groups:
  - build
  development: true
- name: reap
  groups:
  - build
  development: true
- name: qed
  groups:
  - test
  development: true
dependencies: []
conflicts: []
repositories:
- uri: git://github.com/rubyworks/minitap.git
  scm: git
  name: upstream
resources:
  home: http://rubyworks.github.com/minitap
  docs: http://rubydoc.info/gems/minitap
  code: http://github.com/rubyworks/minitap
  bugs: http://github.com/rubyworks/minitap/issues
  mail: http://groups.google.com/group/rubyworks-mailinglist
extra: {}
load_path:
- lib
revision: 0
summary: TAP-Y/J reporters for MiniTest
title: MiniTap
version: 0.3.3
name: minitap
description: MiniTap provides a custom MiniTest reporter that outs TAP-Y or TAP-J
  formatted output.
organization: rubyworks
date: '2012-02-01'
