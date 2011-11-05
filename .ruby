---
source:
- meta
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
- name: detroit
  groups:
  - build
  development: true
- name: reap
  groups:
  - build
  development: true
dependencies: []
conflicts: []
repositories:
- uri: git://github.com/rubyworks/minitap.git
  scm: git
  name: upstream
resources:
  home: http://rubyworks.github.com/minitap
  code: http://github.com/rubyworks/minitap
extra: {}
load_path:
- lib
revision: 0
summary: TAP-Y/J reporters for MiniTest
title: MiniTap
version: 0.3.2
name: minitap
description: MiniTap provides a custom MiniTest reporter that outs TAP-Y or TAP-J
  formatted output.
organization: rubyworks
date: '2011-11-05'
