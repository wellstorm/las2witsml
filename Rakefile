directory "lib"

file "las2witsml-0.1.4.gem"  => ["las2witsml.gemspec", "lib/las2witsml.rb", "lib/las_file.rb", "lib/witsml_file.rb", "bin/las2witsml"] do
  sh "gem build las2witsml.gemspec"
end

task :default => "las2witsml-0.1.4.gem"

