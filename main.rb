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
include_class "javax.swing.JFileChooser"
include_class 'java.awt.event.ActionEvent'
include_class 'java.awt.event.ActionListener'

include_class "java.lang.System"

module Processing
  SKETCH_PATH = "./"
end

class Main < Processing::App
  
  attr_accessor :nes
  
  include Palette
  include Constants
  

  def setup
    @title = "RubyNES"
    
    size 256, 241, P2D
    
    # For the Mac
    System.setProperty "apple.laf.useScreenMenuBar", "true"
    
    # Set up the menu bar
    @menu_bar = JMenuBar.new
    @frame.setJMenuBar @menu_bar
    
    @file_menu = JMenu.new "File"
    @menu_bar.add @file_menu
    @load_item = JMenuItem.new "Load ROM"; @file_menu.add @load_item
    @load_item.add_action_listener LoadMenuActionListener.new
    
    @power_on_item = JMenuItem.new "Power On"; @file_menu.add @power_on_item
    @power_on_item.add_action_listener PowerOnMenuActionListener.new
    
    @exit_item = JMenuItem.new "Exit"; @file_menu.add @exit_item
    @exit_item.add_action_listener ExitMenuActionListener.new
    
    @options_menu = JMenu.new "Options"
    @menu_bar.add @options_menu
    @show_pattern_tables_item = JMenuItem.new "Show Pattern Tables"; @options_menu.add @show_pattern_tables_item
    @show_pattern_tables_item.add_action_listener ShowPatternTablesMenuActionListener.new
    
    @debug_item = JCheckBoxMenuItem.new "Debug?"; @options_menu.add @debug_item
    @debug_item.add_action_listener DebugMenuActionListener.new
    
    
    # Now initialize the actual NES emulator
    @nes = NES.new
    
    # 1/30 of a second, NTSC refresh rate.
    frameRate 30
    
  end
  
  def draw
    if @nes.is_power_on?
      @nes.run_one_frame
    
      repaint
    end
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

class LoadMenuActionListener
  include ActionListener
  def action_performed(event)
    c = JFileChooser.new
    
    rVal = c.showOpenDialog(MAIN.frame)
    if (rVal == JFileChooser::APPROVE_OPTION)
      rom_file = c.getSelectedFile # Returns a Java File
      file = rom_file.getAbsolutePath
      if file != nil and not file.empty?
        MAIN.frame.setTitle "RubyNES (#{rom_file.getName})"
        MAIN.nes.load_rom file 
      end
    end
  end
end

class PowerOnMenuActionListener
  include ActionListener
  def action_performed(event)
    MAIN.nes.power_on if MAIN.nes.rom_file_path != nil and not MAIN.nes.rom_file_path.empty?
  end
end

class ExitMenuActionListener
  include ActionListener
  def action_performed(event)
    System.exit 0
  end
end

class ShowPatternTablesMenuActionListener
  include ActionListener
  def action_performed(event)
  end
end

class DebugMenuActionListener
  include ActionListener
  def action_performed(event)
    debugging = debugging ? false : true
    if debugging
      DEBUG.enable_debugging
    else
      DEBUG.disable_debugging
    end
  end
end

