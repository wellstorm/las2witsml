#require 'las_file'
require 'time'
require 'tempfile'

class WitsmlFile
  
  UNITS = {'ft'=>'ft',      
    'klbs'=>'klbf',                 
    'PSI'=>'psi',
    'SPM'=>'1Pmin',
    'RPM'=>'revPmin',
    'UNITS'=>'ftTlbf',
    'ft/hr'=>'ftPh' ,
    'percent'=>'%',
    'bbl'=>'bbl' ,
    'ton-miles'=>'tonfUSTmi',
    'strokes'=>'unitless',
    'GPM'=>'galUSPmin'   ,
    'hrs'=>'h' ,
    'amps'=>'A' ,
    'ppm'=>'ppm',
    'barrels'=>'bbl',
    'ft/min'=>'ftPmin',
    'ksi'=>'kpsi',
    'cm'=>'cm',
    'ft per hour'=>'ftPh',
    'min/ft'=>'minPft'}

  def initialize(out, witsml_version = 1410)
    @indent = 0
    @out = out
    @witsml_version = witsml_version
  end
  

  def digest_las(las_file)
    #pre chew the las

    #merge date and time
    lcis = las_file.log_curve_infos
    
    #Set these variables, which depend on whether we have a time or a depth log:
    # new_lcis : possibly modified (to merge date+time) list of logCurveInfos
    # index_lci: the LCI of the index curve
    # is_index_index: proc to test the given integer to see whether it is one of the possibly one or two index curve indexes
    # get_index: proc to extract the index from an array of values
    
    if las_file.measured_depth_unit then
      # it's a depth log
      # use the unaltered array of lcis
      new_lcis = lcis
      index_lci = lcis[0]
      
      is_index_index = lambda {|i| (i == 0) }
      get_index = lambda { |values| values[0] }
      
    else
      
      #it's a time log
      date_index, time_index, date_fmt = make_time_indexes(lcis)
      
      # make the new lci for the merged index. Name it 'DATETIME'
      index_lci =  LogCurveInfo.new('DATETIME')
      
      rest_lcis = lcis.reject {|lci| ['time', 'date'].member?(lci.mnemonic.downcase)}    
      
      # use this new array of lcis now
      new_lcis = [index_lci] + rest_lcis
      is_index_index = lambda {|i| (i == time_index || i == date_index) }
      get_index = lambda do |values|
        date = values[date_index]
        #$stderr.puts "date #{date} fmt = #{date_fmt}"
       
        if date_fmt == '1' then
          #$stderr.puts "date = #{date}"
          offset = las_file.start_date_time_index
          dtf = date.to_f
          if (dtf < 86400000 && offset) then
            dt = Time.at(date.to_f + offset.to_f).iso8601
          else
            dt = Time.at(date.to_f).iso8601
          end
        else
          #if we have "mmddyy", munge it so the parser works
          date = date.sub(/(\d\d)(\d\d)(\d\d)/, '\2/\3/\1') if date_fmt == 'yymmdd'
          time = values[time_index]
          # Pason does not put colons between time components; SLB does:
          time = time.sub(/(\d\d)(\d\d)(\d\d)/, '\1:\2:\3') if /\d\d\d\d\d\d/=~ time
          dt = Time.parse(time + ' ' + date).iso8601
        end
        dt
      end        
    end
    [new_lcis, index_lci, is_index_index, get_index]
  end
 
 
 
  
  def from_las_file(las_file, uid_well='$UIDWELL', uid_wellbore='$UIDWELLBORE', uid='$UID', name='$NAME', verbose=false)
    new_lcis, _, is_index_index, get_index = digest_las(las_file)  #unused index_lci
 
    if @witsml_version >= 1410
      ns = 'http://www.witsml.org/schemas/1series'
      vers = '1.4.1.0'
    else
      ns = 'http://www.witsml.org/schemas/131'
      vers = '1.3.1.1'
    end
    
    index_curve = new_lcis[0].mnemonic  # assume first column is index
    add_element('logs',{'xmlns'=>ns, 'version'=>vers}) do
      add_element('log', {'uidWell' => uid_well, 'uidWellbore'=>uid_wellbore, 'uid' => uid}) do
        add_text_element  'nameWell', name
        add_text_element  'nameWellbore', name
        add_text_element  'name', name
        #add_text_element  'dataRowCount', las_file.curve_values.length
        add_text_element  'serviceCompany', las_file.service_company
        add_text_element  'description', 'Created by Wellstorm LAS Import'

        measured_depth_unit = normalize_unit(las_file.measured_depth_unit);
      
        if measured_depth_unit then
          add_text_element  'indexType', 'measured depth'
          add_text_element  'startIndex', las_file.start_measured_depth_index, {'uom' => measured_depth_unit} if las_file.start_measured_depth_index
          add_text_element  'endIndex', las_file.stop_measured_depth_index, {'uom' => measured_depth_unit} if las_file.stop_measured_depth_index        
        else
          add_text_element  'indexType', 'date time'


          #puts ("start index in LAS is #{las_file.start_date_time_index}")

          add_text_element  'startDateTimeIndex', las_file.start_date_time_index.iso8601 if las_file.start_date_time_index
          add_text_element  'endDateTimeIndex', las_file.stop_date_time_index.iso8601 if las_file.stop_date_time_index
        end 
        #add_text_element  'direction' 
        
        if @witsml_version >= 1410
          add_text_element  'indexCurve', index_curve
        else
          add_text_element  'indexCurve', index_curve, {'columnIndex'=>1}
        end
        add_text_element  'nullValue', las_file.null_value

       
        begin
          # use this new array of curve values we build
          tempfile = Tempfile.new 'las2witsml'

          #keep track of start/stop for each channel
          start = []
          stop = []

          las_file.each_data_line(verbose) do |values|
            #$stderr.puts values
            idx = get_index.call(values)
            tempfile << idx
            #$stderr.puts "idx #{idx}"
            values.each_with_index do |v, i|
            
              start[i] = idx if start[i].nil? and v != las_file.null_value
              stop[i] = idx if v != las_file.null_value
              tempfile << ",#{v}" if  !is_index_index.call(i) 

             # $stderr.puts "put #{v} on tempfile"
            end
            tempfile << $/
            nil
          end
          $stderr.puts "done adding lines to tempfile" if verbose   
 
          tempfile.rewind 

          $stderr.puts "rewound #{tempfile}" if verbose
 
          # Now we can build the lcis, surveying each curve for its min/max indexes
          new_lcis.each_with_index do |lci, index|
            add_log_curve_info lci, (index + 1), start[index+1],  stop[index+1], measured_depth_unit
          end

          $stderr.puts "added #{new_lcis.length} LCIs" if verbose   
        
          
          # Now add the curve data
          add_element 'logData' do
            if @witsml_version >= 1410
              add_text_element 'mnemonicList', new_lcis.map{|lci| lci.mnemonic}.join(',')
              add_text_element 'unitList', new_lcis.map{|lci| lci.unit}.join(',')              
            end 

            n = 0
            tempfile.each_line do |values|
              add_text_element 'data', values
              n = n + 1
              $stderr.puts "converted #{n} lines to WITSML" if (verbose && n % 1000 == 0 )
            end
            $stderr.puts "converted a total of #{n} lines to WITSML" if verbose
          end
        rescue
          tempfile.close true
        end

      end
    end
  end
  
  private
  def add_element name, attrs = {}, one_liner = false
    @indent.times {@out.write " "}
    @out.write "<#{name}"
    attrs.each_pair {|attr, val| @out.write " #{attr}='#{escape_attr(val)}'"}
    if block_given?
      @out.write ">"
      @out.write "\n" if !one_liner
      @indent += 2
      yield
      @indent -= 2
      if !one_liner
        @out.write "\n"
        @indent.times {@out.write " "}
      end
      @out.write "</#{name}>\n"
    else
      out.write "/>\n"
    end
  end
  
  def add_text_element(name, text, attrs = {})
    add_element name, attrs, true do
      @out.write escape_text(text)
    end
  end
  
  def add_log_curve_info(las_lci, column_index, min_index, max_index, measured_depth_unit)
    add_element('logCurveInfo', {'uid' => las_lci.mnemonic[0..63]}) do
      add_text_element  'mnemonic', las_lci.mnemonic[0..31]
      add_text_element  'unit', las_lci.unit.downcase if las_lci.unit
      
      if measured_depth_unit then
        add_text_element  'minIndex', min_index, {'uom'=>measured_depth_unit} if min_index
        add_text_element  'maxIndex', max_index, {'uom'=>measured_depth_unit} if max_index 
      else
        add_text_element  'minDateTimeIndex', min_index  if min_index
        add_text_element  'maxDateTimeIndex', max_index if max_index
      end
      if @witsml_version < 1410
        add_text_element  'columnIndex', column_index.to_s
      end
      add_text_element  'curveDescription',las_lci.description if las_lci.description && las_lci.description.length > 0
    end
  end

  def escape_attr(text)
    escape_text(text).sub(/'/, "&pos;").sub(/"/, "&quot;")
  end
  def escape_text(text)
    text.to_s.strip.sub(/&/, "&amp;").sub(/</, "&lt;")
  end



  def make_time_indexes(lcis) 
 
    # Typically we see DATE and TIME
    # We can also see only TIME in which case we expect long integer seconds since 1970
    # (There's no spec that says that; but this data comes from SLB's IDEAL which uses Unix epoch)
    # M/D Totco declares one curve named DATE. It has space separated data and time.

    
    date_index = lcis.collect {|lci| lci.mnemonic.downcase}.index('date')
    time_index = lcis.collect {|lci| lci.mnemonic.downcase}.index('time') 
    
    $stderr.puts("date_index #{date_index}, time_index #{time_index}")    

 
    if !time_index then
      #assume time will be in the next column
      time_index = (date_index + 1) if date_index
    end
    # TODO we never used time_fmt -- why? commenting to suppress warning
    #time_fmt = lcis[time_index].unit.downcase
    
    if !date_index then
      date_index = time_index if time_index
      date_fmt = '1'   # to signify integers since 1/1/1970
      $stderr.puts 'using integer dates'
    else
      date_fmt = lcis[date_index].unit.downcase
    end
    
    # at the moment we understand times of format "hhmmss"
    # and dates "d" or "mmddyy"
    raise "No TIME or DATE" if (!time_index && !date_index)
    
    [date_index, time_index, date_fmt]
          
  end

  def normalize_unit(las_unit)
    # translate to witsml unit
    # n.b. for now we only do depth units!
    # see https://svn.wellstorm.com/projects/wsp/ticket/274#comment:3

    return las_unit if !las_unit
    
    map_las_to_witsml_units = {
      'f'=>'ft', 
      'feet'=>'ft',
      'foot'=>'ft',
      'meters'=>'m',
      'meter'=>'m'}

# just a few random ones from CWLS web site:
# RHOB  .K/M3       45 350 02 00 :  2       BULK DENSITY
#NPHI  .VOL/VO     42 890 00 00 :  3       NEUTRON POROSITY - SANDSTONE
#MSFL  .OHMM       20 270 01 00 :  4       Rxo RESISTIVITY
# SP    .MV         07 010 01 00 :  8       SPONTANEOUS POTENTIAL
#GR    .GAPI       45 310 01 00 :  9       GAMMA RAY
#CALI  .MM         45 280 01 00 :  10      CALIPER
#DRHO .K/M3        45 356 01 00 :  11      DENSITY CORRECTION
 
    map_las_to_witsml_units[las_unit.downcase] || las_unit.downcase
    
  end

end
