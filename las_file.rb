require 'time'


class LogCurveInfo
  attr_accessor :mnemonic,:unit,:description
  def initialize(mnemonic, unit = nil, description = nil)
    @mnemonic = mnemonic; @unit = unit; @description = description
  end
end

class LasFile

  
  attr_reader :log_curve_infos, 
  :measured_depth_unit,
  :start_measured_depth_index, :stop_measured_depth_index, 
  :start_date_time_index, :stop_date_time_index,
  :null_value, :service_company, :curve_values,
  :elevation_kelly_bushing, :log_measured_from, :permanent_datum, :above_permanent_datum
    
  def initialize(io)
    @log_curve_infos = []
    @curve_values = []
    @in = io
  end
  
  def process verbose=false
    while block(verbose); end
  end

  #each_data_line is an optimization so we don't have to store 8 million
  # or so ruby objects in memory (uses up 1.6GB).

  def each_data_line verbose=false
    lines_processed = 0
    while line = next_line
      yield(line.split)
      lines_processed = lines_processed + 1
      $stderr.puts "processed #{lines_processed} lines" if (verbose && lines_processed % 1000 == 0 )
    end
    
  end
    
  private
  
  def block(verbose)
    line = next_line
    section = /^~([a-zA-Z]+).*/.match(line)
    
    $stderr.puts "processing #{section [1]} section" if verbose
    case section [1].downcase
    when 'well', 'w'
      well_information
    when 'version', 'v'
      version_information
    when 'curve', 'c'
      curve_information
    when 'parameter', 'p'
      parameter_information
    when 'other', 'o'
      other_information
    when 'a'
      #assume this is the last block. we'll deliver 
      # curve data on demand, in each_data_line
      #curve_data(verbose) #how we used to process ~A
    end if section
  end
  
 
  def version_information
    skip_block # we don't care for now
  end
  
  def is_depth_unit(unit)
    if unit then
      dunit = unit.downcase
      if (dunit == 'ft' || dunit == 'f' || dunit == 'm' || dunit == 'cm' || dunit == 'in') 
        dunit
      end
    end
  end

  def parse_date_time (data,info, unit='s')
    begin
      Time.parse(data)    #nicely handles the case of either dd/mm/yy or hh:mm:ss
    rescue
      begin
        offset = data.to_f  #for now I'm assuming unit of seconds

        # The Chevron SLB data uses DATE as the units for seconds since 1/1/1970.
        if unit.downcase == 'date'
          Time.at(offset)
        else
          base = Time.parse(info) # hah! This works for the Scientif Drilling LAS files. They put in comments: 11/30/08 18:00:00.00 (Central Standard Time)"
          base + offset
        end
      rescue
        # ok, ok... nice try, but info did not have a date in it.
        offset = data.to_f  #for now I'm assuming unit of seconds
        Time.at(offset)
      end
    end
  end   

  def well_information
    #['STRT','STOP','STEP','NULL','COMP','WELL','FLD','LOC','PROV','CNTY','STAT','CTRY','SRVC','DATE','UWI','API']    
    while m = /^([^~][^\.]+)\.([^\s]*)(.*):(.*)$/.match(line = next_line)
      mnemonic, unit, data, info = [*m].slice(1, 4).collect{|s| s.strip}
 
      case mnemonic
      when 'STRT'
        if dunit = is_depth_unit(unit)  then
          @measured_depth_unit = dunit
          @start_measured_depth_index = data.to_f
        else
          @start_date_time_index = parse_date_time(data, info, unit)          
        end
      when 'STOP'
        if  dunit = is_depth_unit(unit) then 
          @measured_depth_unit = unit
          @stop_measured_depth_index = data.to_f
        else
          @stop_date_time_index = parse_date_time(data, info, unit)          

        end
      when 'STEP'
        @step_increment = data.to_f
      when 'NULL'
        @null_value = data
      when 'SRVC'
        @service_company = data    
      end
    end
    put_back_line(line)
  end
  
  def curve_information
    while m = /^([^~][^\.]+)\.([^: \t]*)\s*([^:]*):(.*)$/.match(line = next_line)
      mnemonic, unit, api_code, description = [*m].slice(1, 4).collect {|s| s.strip}
      log_curve_info mnemonic, unit, description
    end
    put_back_line(line)    
  end

  def parameter_information
# BHT  .DEGF     210.00000                 :Bottom Hole Temperature (used in calculations)
# DFD  .LB/G       9.70000                 :Drilling Fluid Density
# DFL  .                                   :Drilling Fluid Loss
# DFV  .S         54.00000                 :Drilling Fluid Viscosity
# MATR .        LIME                       :Rock Matrix for Neutron Porosity Corrections
# MDEN .G/C3       2.71000                 :Matrix Density
# RANG .        101W                       :Range
# TOWN .        154N                       :Township
# SECT .        2                          :Section
# APIN .        33-105-02119               :API Serial Number
# FL1  .        285 FNL & 2000 FWL         :Field Location Line 1
# FL   .        LOT3                       :Field Location
# FN   .        TODD                       :Field Name
# WN   .        WILLISTON AIRPORT 2-11     :Well Name
# CN   .        BRIGHAM OIL & GAS  L.P.    :Company Name
# RUN  .          1                        :RUN NUMBER
# PDAT .        GROUND LEVEL               :Permanent Datum
# EPD  .F         1972.000000              :Elevation of Permanent Datum above Mean Sea Level
# LMF  .          KELLY BUSHING            :Logging Measured From (Name of Logging Elevation Reference)
# APD  .F          19.000000               :Elevation of Depth Reference (LMF) above Permanent Dat
       
    while m = /^([^~][^\.]+)\.([^\s]*)(.*):(.*)$/.match(line = next_line)
      mnemonic, unit, data, info = [*m].slice(1, 4).collect{|s| s.strip}
 
      case mnemonic
      when 'RUN'
        @run_number = data.to_i
      when 'PDAT' 
        @permanent_datum = data
      when 'EPD', 'EGL'
        @elevation_permanent_datum = data.to_f
        @elevation_unit = unit
      when 'LMF'
        @log_measured_from = data
      when 'APD'
        @above_permanent_datum = data.to_f
        @elevation_unit = unit
      when 'EKB'
        @elevation_kelly_bushing = data
        @elevation_unit = unit
      end
    end

    if @elevation_kelly_bushing
      @log_measured_from = "KELY BUSHING"
    end
    if @elevation_kelly_bushing and  @elevation_permanent_datum and not  @above_permanent_datum then
      @above_permanent_datum = @elevation_kelly_bushing.to_f - @elevation_permanent_datum.to_f 
    end
    if not @elevation_kelly_bushing and  @elevation_permanent_datum and  @above_permanent_datum then
      @elevation_kelly_bushing =  @above_permanent_datum.to_f +  @elevation_permanent_datum.to_f
    end

    put_back_line(line)
  end
  
  def other_information
    skip_block  
  end

  def next_line
    if @next_line
      line = @next_line
      @next_line = nil
    else
      while /^((#.*)|(\s*))$/ =~(line = @in.gets);end   
    end
    line
  end
 
  def put_back_line(line)
    @next_line = line
  end
  
  def skip_block
    while not /^~.*$/ =~(line = @in.readline);end   
    put_back_line(line)    
  end
  
  def log_curve_info mnemonic, las_unit, description
    @log_curve_infos << LogCurveInfo.new(mnemonic, las_unit.downcase, description)

  end
  


end



