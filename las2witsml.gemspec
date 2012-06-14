Gem::Specification.new do |s|
  s.name = %q{las2witsml}
  s.version = "0.1.2"
  s.date = %q{2012-06-14}
  s.authors = ["Hugh Winkler"]
  s.email = %q{hugh.winkler@wellstorm.com}
  s.summary = %q{Converts Log ASCII Standard (LAS) files to WITSML <log> objects.}
  s.homepage = %q{https://github.com/wellstorm/las2witsml/}
  s.description = %q{A command line tool and a library for converting Log ASCII Standard (LAS) files to WITSML <log> objects.}
  s.files = [ "README", "LICENSE", "lib/las2witsml.rb", "lib/las_file.rb", "lib/witsml_file.rb"]
  s.executables = [ "las2witsml" ]
end
