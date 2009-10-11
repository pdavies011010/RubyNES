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

# Initialize Debugger as a global constant 'DEBUG'. Turn Debugging off by default.
DEBUGGING=false 
DEBUG = Debugger.new(DEBUGGING)

class Main < Processing::App
  attr_accessor :nes
  
  include Palette
  include Constants

  def setup
    rom_file = ARGV[0]
    
    size 256, 241, P2D
    
    # Now initialize the actual NES emulator
    @nes = NES.new()
    
    @nes.load_rom rom_file if rom_file != nil and not rom_file.empty?
    @title = "Ruby NES (#{rom_file})"
    
    # 1/30 of a second, NTSC refresh rate.
    frameRate(30)
    
    @nes.power_on
    
  end
  
  def draw
    @nes.run_one_frame
    
    repaint
  end
  
  def repaint
    ppu = @nes.ppu
    
    loadPixels
    ppu.screen_buffer.each_index { |scanline_index|
      if (scanline_index != 0) # Scanline 1 in the ppu is a dummy scanline (nothing drawn)
        scanline = ppu.screen_buffer[scanline_index]
        scanline.each_index { |pixel_index|
          pixel = COLORS[scanline[pixel_index]]
          
          pixels[((scanline_index - 1) * 256) + pixel_index] = color(((pixel & 0xFF0000) >> 16), ((pixel & 0xFF00) >> 8), (pixel & 0xFF)) # 
        }
      end
    }
    updatePixels
  end

end