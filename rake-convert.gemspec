Gem::Specification.new {|s|
    s.name         = 'rake-convert'
    s.version      = '0.0.1'
    s.author       = 'meh.'
    s.email        = 'meh@paranoici.org'
    s.homepage     = 'http://github.com/meh/rake-convert'
    s.platform     = Gem::Platform::RUBY
    s.summary      = 'Convert a Rakefile to Makefile and configure script'
    s.files        = Dir.glob('lib/**/*.rb')
    s.require_path = 'lib'
    s.has_rdoc     = false
}
