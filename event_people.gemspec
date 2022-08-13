# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'event_people/version'

Gem::Specification.new do |spec|
  spec.name          = 'event_people'
  spec.version       = EventPeople::VERSION
  spec.authors       = ['Pin People']
  spec.email         = ['contato@pinpeople.com.br']

  spec.summary       = 'Expose an api to produce and consume events.'
  spec.description   = 'Tool to produce and consume events to a distributed and async architecture'
  spec.homepage      = 'https://github.com/pin-people/event_people_ruby'
  spec.license       = 'GNU LESSER GENERAL PUBLIC LICENSE V3'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.' unless spec.respond_to?(:metadata)

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pry-meta'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'

  spec.add_dependency 'bunny', '~> 2.7'
end
