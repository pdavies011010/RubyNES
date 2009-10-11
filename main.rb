require "rubygems"
gem "ruby-processing"
require "ruby-processing"
require "nes"
require "debugger"
require "palette"
require "constants"

module Processing
  SKETCH_PATH = "./"
end

class Main < Processing::App
  attr_accessor :nes
  
  include Palette
  include Constants

  def setup
    x2 = ARGV[0]
    y2 = ARGV[1]
    
    @title = "Ruby NES"
    size 280, 280, P2D
    background 255, 0, 0  # Red
    stroke 0, 0, 255 # Blue
    line 10, 10, 270, 270
  end
  
  def draw
    
  end

end