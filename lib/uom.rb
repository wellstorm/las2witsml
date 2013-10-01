require 'rubygems'
require 'json'

class Uom

  def initialize(path=nil)
    if !path then
      path = Uom::default_uom_file
    end
    @uom_map = load_uom_map path
  end

  def translate (in_uom)
    @uom_map[in_uom.downcase]
  end

  def self.default_uom_file
    File.expand_path(File.dirname(__FILE__) + "/uom.json")
  end

private
  def load_uom_map path
    JSON.parse( File.open( path, 'r') { |f| f.read })
  end

  def get_uom_map
    if @@uom_map == Nil then
      
    end
  end
end

