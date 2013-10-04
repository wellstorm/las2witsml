#require 'java'
require 'las_file'
require 'witsml_file'
class Las2Witsml
  def run in_stream, out_stream, uid_well, uid_wellbore, uid_log, name_log, version = 1411, verbose=false, uom_file=nil
    begin
 
      las =LasFile.new in_stream 
      las.process verbose
      $stderr.puts 'processed las file'
      
      witsml = WitsmlFile.new out_stream, version, uom_file
      $stderr.puts 'made witsmlFile' if verbose
      witsml.from_las_file(las, uid_well, uid_wellbore, uid_log, name_log,  verbose)   
      $stderr.puts 'read from lasFile' if verbose
      out_stream.flush
      true
    rescue => e
      $stderr.puts e.backtrace.join("\n")
      false
    rescue  WitsmlFile::ConversionError => e
      $stderr.puts e.message
      false
    end
  end
end
