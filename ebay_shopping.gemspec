Gem::Specification.new do |s|

  s.name = 'ebay_shopping'
  s.version = "0.1.1"
  s.summary = %q{A Ruby library for Ebay's Shopping API. By Chris Taggart}
  s.description = %q{The ebay_shopping gem is a Ruby library for Ebay's Shopping API (http://developer.ebay.com/products/shopping/).}
  s.authors = ["Chris Taggart"]
  s.autorequire = %q{ebay_shopping}
  s.homepage = "http://github.com/ctagg/ebay_shopping"
  s.requirements = ["Ebay Shopping API key"]
  s.date = %q{2009-02-07}
  s.email = %q{chris.taggart@pushrodmedia.co.uk}
  
  s.files = Dir['lib/**/*.rb'] + Dir['test/**/*.rb']
  s.require_path = 'lib'
  # s.autorequire = 'builder'
  # s.has_rdoc = true
  # s.extra_rdoc_files = Dir['[A-Z]*']
  
end
