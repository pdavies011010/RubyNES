gem "fxruby"
require "fox16"
require "nes"
require "debugger"
require "palette"

# Initialize Debugger as a global constant 'DEBUG'. Turn Debugging off by default. 
DEBUG = Debugger.new(false)

class Main
  attr_accessor :nes
  
  include Fox
  include Palette
  
  def initialize
    super
    
    # Create RubyFX app and main window
    @app = FXApp.new
    
    # Now initialize the actual NES emulator
    @nes = NES.new()
    
    # Buffer of 240 scanlines, 341 pixels per line (FXColor entries)
    @screen_buffer = Array.new(240, Array.new(341, 0))
    
    # Build the application windows, menu bar, etc.
    @main_window = FXMainWindow.new(@app, "rNES", nil, nil, DECOR_ALL, 200, 200, 360, 280)
    @menu_bar = FXMenuBar.new(@main_window) { |bar|
      file_menu_pane = FXMenuPane.new(bar)
      
      file_open_command = FXMenuCommand.new(file_menu_pane, "Load ROM" ) 
      file_open_command.connect(SEL_COMMAND) { |sender, selector, data|
        open_rom
      }
      
      file_power_command = FXMenuCommand.new(file_menu_pane, "Power On" )
      file_power_command.connect(SEL_COMMAND) { |sender, selector, data|
        power_on
      }
      
      file_exit_command = FXMenuCommand.new(file_menu_pane, "Exit" )
      file_exit_command.connect(SEL_COMMAND) { |sender, selector, data|
        exit
      }
        
      option_menu_pane = FXMenuPane.new(bar)
     
      option_debug_check = FXMenuCheck.new(option_menu_pane, "Debug?")
      option_debug_check.connect(SEL_COMMAND) { |sender, selector, data|
        if (data == TRUE)
          DEBUG.enable_debugging
        else
          DEBUG.disable_debugging
        end
      }
      
      file_menu_title = FXMenuTitle.new(bar, "File" ,
      :popupMenu => file_menu_pane)
      
      option_menu_title = FXMenuTitle.new(bar, "Options" ,
      :popupMenu => option_menu_pane)
    }
    
    # Canvas Frame
    canvas_frame = FXVerticalFrame.new(@main_window,
      FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT,
      :padLeft => 10, :padRight => 10, :padTop => 10, :padBottom => 10)
    
    # Canvas
    @canvas = FXCanvas.new(canvas_frame, :opts => (FRAME_SUNKEN|
      FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT))
    @canvas.connect(SEL_PAINT, method(:canvas_repaint))
    
    # Create the application windows
    @app.create
    
    # Show the main window and run the app
    @main_window.show
    @app.run
  end
  
  def open_rom
    rom = FXFileDialog.getOpenFilename(@main_window, "Select ROM File...", ".\\", "*.nes", 0)
    @nes.load_rom rom if rom != nil and not rom.empty?
    @main_window.title = "rNes (#{rom})"
  end
  
  def power_on
    @nes.power_on if @nes.rom_file_path != nil and not @nes.rom_file_path.empty?
    
    @app.addTimeout(33, :repeat => true) { |sender, sel, event|
      # Check for pressed keys and build 'buttons pressed' array
      
      # 1/30 of a second, NTSC refresh rate. 
      @nes.run_one_frame
        
      refresh_screen_buffer
      @canvas.update
    }
  end
  
  def exit
    @app.destroy # Close all windows
    @app.closeDisplay
    @app.stop
  end
  
  def get_buttons
    # Returns an array of button symbols
  end
  
  def canvas_repaint(sender, sel, event)
    FXDCWindow.new(@canvas, event){|dc|
      # Fill in onscreen buffer from PPU buffer
      # Note: This has got to be the slowest possible way to do this. 
      @screen_buffer.each_index { |scanline_index|
        scanline = @screen_buffer[scanline_index]
        scanline.each_index { |pixel_index|
          # Pixel is the RGB (24-bit) color value for this pixel
          # Now do something with it!
          dc.foreground = @screen_buffer[scanline_index][pixel_index]
          dc.drawPoint(pixel_index,scanline_index)
        }
      }
    }
  end
  
  def refresh_screen_buffer
    ppu = @nes.ppu
        
    # Fill in onscreen buffer from PPU buffer
    ppu.screen_buffer.each_index { |scanline_index|
      scanline = ppu.screen_buffer[scanline_index]
      scanline.each_index { |pixel_index|
        pixel = COLORS[scanline[pixel_index]]
        # Pixel is the RGB (24-bit) color value for this pixel
        # Now do something with it!
        @screen_buffer[scanline_index][pixel_index] = FXRGB((pixel & 0xFF0000) >> 16, (pixel & 0xFF00) >> 8, (pixel & 0xFF))
      }
    }
  end
end