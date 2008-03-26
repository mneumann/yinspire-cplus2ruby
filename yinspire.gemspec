require 'rubygems'

spec = Gem::Specification.new do |s|
  s.name = "yinspire"
  s.version = "0.1.0"
  s.summary = "An efficient Spiking Neural Net Simulator"
  s.files = Dir['**/*']
  s.add_dependency('cplus2ruby', '>= 1.1.0')
  s.executables = ['yinspire']

  s.author = "Michael Neumann"
  s.email = "mneumann@ntecs.de"
  s.homepage = "http://www.ntecs.de/projects/yinspire/"
  s.rubyforge_project = "yinspire"
end

if __FILE__ == $0
  Gem::manage_gems
  Gem::Builder.new(spec).build
end
