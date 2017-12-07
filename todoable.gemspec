Gem::Specification.new do |s|
  s.name        = 'todoable'
  s.version     = '0.0.1'
  s.date        = '2017-12-06'
  s.summary     = "A client to access Teachable's todoable API"
  s.authors     = ['Andy Kriger']
  s.email       = 'andy.kriger@gmail.com'
  s.files       = Dir.glob('lib/**/*')
  s.homepage    = 'https://github.com/locopati/todoable'
  # we could just as easily use the built-in Minitest
  # however, i prefer rspec
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'webmock'
end

