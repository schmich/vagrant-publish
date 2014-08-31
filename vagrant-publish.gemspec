require File.expand_path('lib/vagrant-publish/version.rb', File.dirname(__FILE__))

Gem::Specification.new do |s|
  s.name = 'vagrant-publish'
  s.version = VagrantPublish::VERSION
  s.date = Time.now.strftime('%Y-%m-%d')
  # TODO: Add summary, description.
  s.summary = ''
  s.description = <<-END
  END
  s.authors = ['Chris Schmich']
  s.email = 'schmch@gmail.com'
  s.files = Dir['{lib}/**/*.rb', 'bin/*', '*.md', 'LICENSE']
  s.require_path = 'lib'
  s.homepage = 'https://github.com/schmich/vagrant-publish'
  s.license = 'MIT'
  s.required_ruby_version = '>= 1.9.3'
  # TODO: Add version specifications.
  s.add_runtime_dependency 'rest_client'
  s.add_runtime_dependency 'dropbox-sdk'
  s.add_runtime_dependency 'hashery'
  s.add_development_dependency 'rake'
end
