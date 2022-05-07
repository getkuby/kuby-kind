$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'kuby/kind/version'

Gem::Specification.new do |s|
  s.name     = 'kuby-kind'
  s.version  = ::Kuby::Kind::VERSION
  s.authors  = ['Cameron Dutro']
  s.email    = ['camertron@gmail.com']
  s.homepage = 'http://github.com/getkuby/kuby-kind'

  s.description = s.summary = 'Kind provider for Kuby.'

  s.platform = Gem::Platform::RUBY

  s.add_dependency 'kind-rb', '~> 0.1'

  s.require_path = 'lib'
  s.files = Dir['{lib,spec}/**/*', 'Gemfile', 'LICENSE', 'CHANGELOG.md', 'README.md', 'Rakefile', 'kuby-kind.gemspec']
end
