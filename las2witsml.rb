#require 'java'
#require 'las_file'
#require 'witsml_file'
class Las2Witsml
  def run in_stream, out_stream, uid_well, uid_wellbore, uid_log, name_log, verbose=false
    begin
 
      las =LasFile.new in_stream 
      las.process verbose
      $stderr.puts 'processed las file'
      
      witsml = WitsmlFile.new out_stream
      $stderr.puts 'made witsmlFile' if verbose
      witsml.from_las_file(las, uid_well, uid_wellbore, uid_log, name_log,  verbose)   
      $stderr.puts 'read from lasFile' if verbose
      out_stream.flush
      true
    rescue => e
      $stderr.puts e.backtrace.join("\n")
      false
    end
  end
end
