Gem::Specification.new do |s|
  s.name = %q{las2witsml}
  s.version = "0.1.3"
  s.date = %q{2013-10-01}
  s.authors = ["Hugh Winkler"]
  s.email = %q{hugh.winkler@drillinginfo.com}
  s.summary = %q{Converts Log ASCII Standard (LAS) files to WITSML <log> objects.}
  s.homepage = %q{https://github.com/wellstorm/las2witsml/}
  s.description = %q{A command line tool and a library for converting Log ASCII Standard (LAS) files to WITSML <log> objects.}
  s.files = [ "README", "LICENSE", "lib/las2witsml.rb", "lib/las_file.rb", "lib/witsml_file.rb", "lib/uom.rb", "lib/uom.json"]
  s.license = 'Apache 2.0'
  s.executables = [ "las2witsml" ]
  s.require_paths = ["lib"]
  s.add_runtime_dependency "json"
end
