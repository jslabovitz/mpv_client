#encoding: utf-8

require_relative 'lib/mpv_client/version'

Gem::Specification.new do |s|
  s.name          = 'mpv_client'
  s.version       = MPVClient::VERSION
  s.summary       = %q{Ruby bindings to the MPV media player, via MPV's JSON-IPC protocol.}
  s.description   = %q{
    MPVClient provides Ruby bindings to the MPV media player, via MPV's JSON-IPC protocol.
  }
  s.author        = 'John Labovitz'
  s.email         = 'johnl@johnlabovitz.com'
  s.homepage      = 'http://github.com/jslabovitz/mpv_client'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_path  = 'lib'

  s.add_dependency 'json', '~> 2.1'

  s.add_development_dependency 'rake', '~> 12.3'
  s.add_development_dependency 'rubygems-tasks', '~> 0.2'
  s.add_development_dependency 'minitest', '~> 5.11'
  s.add_development_dependency 'minitest-power_assert', '~> 0.3'
end