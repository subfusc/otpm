Gem::Specification.new do |s|
  s.name        = 'otpm'
  s.version     = '0.0.2'
  s.licenses    = ['GPL-3.0']
  s.summary     = "OTP management library"
  s.description = "A library that stores OTP secrets sensibly safe and generates codes for you."
  s.authors     = ["Sindre Wetjen"]
  s.email       = ['sindre.w@gmail.com']
  s.homepage    = 'https://github.com/subfusc/otpm'

  s.required_ruby_version = '~> 2'
  s.add_runtime_dependency 'rotp', '~> 3'
  s.add_runtime_dependency 'openssl', '~> 2'

  s.add_development_dependency 'rake', '~> 12'
  s.add_development_dependency 'minitest', '~> 5'
  s.add_development_dependency 'bundler', '~> 1'
  s.add_development_dependency 'fakefs', '~> 0.10'

  s.files       = %x{git ls-files}.split("\n")
  s.executables   = %x{git ls-files -- bin/*}.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
