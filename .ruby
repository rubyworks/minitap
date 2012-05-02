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
- name: ae
  groups:
  - test
  development: true
dependencies: []
alternatives: []
conflicts: []
repositories:
- uri: git://github.com/rubyworks/minitap.git
  scm: git
  name: upstream
resources:
- uri: http://rubyworks.github.com/minitap
  label: Website
  type: home
- uri: http://rubydoc.info/gems/minitap
  type: docs
- uri: http://github.com/rubyworks/minitap
  label: Source Code
  type: code
- uri: http://github.com/rubyworks/minitap/issues
  label: Issue Tracker
  type: bugs
- uri: http://groups.google.com/group/rubyworks-mailinglist
  label: Mailing List
  type: mail
categories: []
extra: {}
load_path:
- lib
revision: 0
summary: TAP-Y/J reporters for MiniTest
title: MiniTap
version: 0.3.4
name: minitap
description: MiniTap provides a MiniTest TAP-Y/J report format suitable for use with
  TAPOUT.
organization: rubyworks
date: '2012-05-02'
