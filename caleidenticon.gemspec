# coding: utf-8
Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '2.2.2'
  s.required_ruby_version = '>= 2.0.0'

  s.name        = 'caleidenticon'
  s.version     = '0.8.0'
  s.license     = 'MIT'

  s.summary     = 'Creates caleidoscopic identicons.'
  s.description = 'Caleidenticon is a customizable generator for caleidoscope-like identicons.'

  s.authors     = ['Janosch Müller']
  s.email       = 'janosch84@gmail.com'
  s.homepage    = 'https://github.com/janosch-x/caleidenticon'

  s.files       = ['lib/caleidenticon.rb']

  s.rdoc_options = ['--charset=UTF-8']
  s.extra_rdoc_files = %w[README.md LICENSE]

  s.add_dependency('bcrypt',   '~> 3.1.10')
  s.add_dependency('oily_png', '~> 1.1.2')
end