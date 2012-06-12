#require 'java'
#require 'las_file'
#require 'witsml_file'
class Las2Witsml
  def run in_stream, out_stream, uid_well, uid_wellbore, uid_log, name_log
    begin
 
      las =LasFile.new in_stream 
      las.process true
      puts 'processed las file'
      
      witsml = WitsmlFile.new out_stream
      puts 'made witsmlFile'
      witsml.from_las_file(las, uid_well, uid_wellbore, uid_log, name_log,  true)   
      puts 'read from lasFile'
      out_stream.flush
      true
    rescue => e
    	puts e.backtrace.join("\n")
    	
      false
    end
  end
end
