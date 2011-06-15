# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rvideo/version"

Gem::Specification.new do |s|
  s.name = %q{rvideo}
  s.version = "0.9.6"

  s.version     = RVideo::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Vivien Schilis, Peter Boling, Jonathan Dahl, Seth Thomas Rasmussen"]
  s.email       = ["vivien@new-bamboo.co.uk"]
  s.homepage    = %q{https://github.com/newbamboo/rvideo}
  s.summary     = %q{Inspect and transcode video and audio files.}
  s.description = %q{Inspect and transcode video and audio files.}

  s.rubyforge_project = "rvideo"

  s.add_dependency "activesupport"
  s.add_dependency "posix-spawn"

  s.add_development_dependency "rake"
  s.add_development_dependency "i18n"
  s.add_development_dependency "rspec"
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
