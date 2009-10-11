require "rubygems"
gem "ruby-processing"
require "ruby-processing"
require "nes"
require "debugger"
require "palette"
require "constants"

include_class "javax.swing.JMenuBar"
include_class "javax.swing.JMenu"
include_class "javax.swing.JMenuItem"
include_class "javax.swing.JCheckBoxMenuItem"

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
    @title = "Ruby NES"
    rom_file = ARGV[0]
    
    size 256, 241, P2D
    
    # Set up the menu bar
    @menu_bar = JMenuBar.new
    @frame.setJMenuBar(@menu_bar)
    
    @file_menu = JMenu.new("File")
    @load_item = JMenuItem.new("Load ROM"); @file_menu.add(@load_item)
    @power_on_item = JMenuItem.new("Power On"); @file_menu.add(@power_on_item)
    @exit_item = JMenuItem.new("Exit"); @file_menu.add(@exit_item)
    @menu_bar.add(@file_menu)
    
    @options_menu = JMenu.new("Options")
    @show_pattern_tables_item = JMenuItem.new("Show Pattern Tables"); @options_menu.add(@show_pattern_tables_item)
    @debug_item = JCheckBoxMenuItem.new("Debug?"); @options_menu.add(@debug_item)
    @menu_bar.add(@options_menu)
    
    
    # Now initialize the actual NES emulator
    @nes = NES.new()
    
    @nes.load_rom rom_file if rom_file != nil and not rom_file.empty?
    @frame.setTitle "Ruby NES (#{rom_file})"
    
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

