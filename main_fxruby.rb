require "fox16"
require "nes"
require "debugger"
require "palette"
require "constants"

# Initialize Debugger as a global constant 'DEBUG'. Turn Debugging off by default. 
DEBUG = Debugger.new(false)

class MainFXRuby
  attr_accessor :nes
  
  include Fox
  include Palette
  include Constants
  
  def initialize
    super
    
    # Create RubyFX app and main window
    @app = FXApp.new
    
    # Now initialize the actual NES emulator
    @nes = NES.new()
    
    # Buffer of 240 scanlines, 256 pixels per line (FXColor entries)
    @screen_buffer = Array.new(240, nil)
    @screen_buffer.each_index {|index|
      @screen_buffer[index] = Array.new(256, 0)
    }
    
    # Build the application windows, menu bar, etc.
    @main_window = FXMainWindow.new(@app, "rNES", nil, nil, DECOR_ALL, 200, 200, 280, 280)
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

      option_pattern_command = FXMenuCommand.new(option_menu_pane, "Show Pattern Tables" )
      option_pattern_command.connect(SEL_COMMAND) { |sender, selector, data|
        show_pattern_tables
      }
     
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

    # Window to show pattern tables
    @pattern_window = FXMainWindow.new(@app, "Pattern Tables", nil, nil, DECOR_ALL, 200, 200, 128, 270)
    pattern_canvas_frame = FXVerticalFrame.new(@pattern_window,
        FRAME_SUNKEN|LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT,
        :padLeft => 10, :padRight => 10, :padTop => 10, :padBottom => 10)
    @pattern_canvas = FXCanvas.new(pattern_canvas_frame, :opts => (FRAME_SUNKEN|
        FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_LEFT))
    @pattern_canvas.connect(SEL_PAINT, method(:pattern_canvas_repaint))

    # Screen Buffers for pattern table display
    # 256 tiles of 8x8 pixels = 128 x 128(FXColor entries)
    @pattern_table0_screen_buffer = Array.new(128, nil)
    @pattern_table0_screen_buffer.each_index {|index|
      @pattern_table0_screen_buffer[index] = Array.new(128, 0)
    }


    @pattern_table1_screen_buffer = Array.new(128, nil)
    @pattern_table1_screen_buffer.each_index {|index|
      @pattern_table1_screen_buffer[index] = Array.new(128, 0)
    }
    
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
    sdc = FXDCWindow.new(@canvas, event){|dc|
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

    sdc.end
  end
  
  def refresh_screen_buffer
    ppu = @nes.ppu
        
    # Fill in onscreen buffer from PPU buffer
    ppu.screen_buffer.each_index { |scanline_index|
      if (scanline_index != 1) # Scanline 1 in the ppu is a dummy scanline (nothing drawn)
        scanline = ppu.screen_buffer[scanline_index]
        scanline.each_index { |pixel_index|
          pixel = COLORS[scanline[pixel_index]]
          # Pixel is the RGB (24-bit) color value for this pixel
          # Now do something with it!
          @screen_buffer[scanline_index - 1][pixel_index] = FXRGB((pixel & 0xFF0000) >> 16, (pixel & 0xFF00) >> 8, (pixel & 0xFF))
        }
      end
    }
  end

  def show_pattern_tables
    @pattern_window.show
  end

  def refresh_pattern_table_screen_buffer
    ppu = @nes.ppu
    mmc = ppu.mmc

    bit_masks = [0x80,0x40,0x20,0x10,0x8,0x4,0x2,0x1]
    byte_1_bit_shift = [7, 6, 5, 4, 3, 2, 1, 0]
    byte_2_bit_shift = [6, 5, 4, 3, 2, 1, 0, -1]
    pattern_table0_palette_buffer = Array.new(128, nil)
    pattern_table0_palette_buffer.each_index {|index|
      pattern_table0_palette_buffer[index] = Array.new(128, 0)
    }

    pattern_table1_palette_buffer = Array.new(128, nil)
    pattern_table1_palette_buffer.each_index {|index|
      pattern_table1_palette_buffer[index] = Array.new(128, 0)
    }


    # Fill in onscreen buffers from the pattern tables
    for pattern_table_index in (PATTERN_TABLE_0_LO..PATTERN_TABLE_0_HI)
      if pattern_table_index % 16 < 8
        tile = (pattern_table_index / 16).floor # Tiles are 16 bytes a piece
        tile_row = (tile / 16).floor # 16 tiles in a scanline
        scanline_index = (tile_row * 8) + (pattern_table_index % 8)
        pixel_index = (tile - (tile_row * 16)) * 8


        pattern_table_byte = mmc.read_ppu_mem(pattern_table_index)
        pattern_table_byte2 = mmc.read_ppu_mem(pattern_table_index + 8)

        pixels = combine_pattern_table_bytes(pattern_table_byte, pattern_table_byte2)
        (0..7).each {|index|
          pattern_table0_palette_buffer[scanline_index][pixel_index + index] = pixels[index]
        }
      end
    end

    for pattern_table_index in (PATTERN_TABLE_1_LO..PATTERN_TABLE_1_HI)
      if pattern_table_index % 16 < 8
        tile = ((pattern_table_index - PATTERN_TABLE_1_LO) / 16).floor # Tiles are 16 bytes a piece
        tile_row = (tile / 16).floor # 16 tiles in a scanline
        scanline_index = (tile_row * 8) + (pattern_table_index % 8)
        pixel_index = (tile - (tile_row * 16)) * 8

        pattern_table_byte = mmc.read_ppu_mem(pattern_table_index)
        pattern_table_byte2 = mmc.read_ppu_mem(pattern_table_index + 8)

        pixels = combine_pattern_table_bytes(pattern_table_byte, pattern_table_byte2)
        (0..7).each {|index|
          pattern_table1_palette_buffer[scanline_index][pixel_index + index] = pixels[index]
        }
      end
    end
    
    pattern_table0_palette_buffer.each_index { |scanline|
      line = pattern_table0_palette_buffer[scanline]
      line.each_index { |pixel|
        # At the moment, not indexing into the image palette, since it doesn't seem to be initializing correctly
        dot = COLORS[line[pixel]]
        @pattern_table0_screen_buffer[scanline][pixel] = FXRGB((dot & 0xFF0000) >> 16, (dot & 0xFF00) >> 8, (dot & 0xFF))
      }
    }

    pattern_table1_palette_buffer.each_index { |scanline|
      line = pattern_table1_palette_buffer[scanline]
      line.each_index { |pixel|
        # At the moment, not indexing into the image palette, since it doesn't seem to be initializing correctly
        dot = COLORS[line[pixel]]
        @pattern_table1_screen_buffer[scanline][pixel] = FXRGB((dot & 0xFF0000) >> 16, (dot & 0xFF00) >> 8, (dot & 0xFF))
      }
    }

  end

  def pattern_canvas_repaint(sender, sel, event)
    refresh_pattern_table_screen_buffer
    
    sdc = FXDCWindow.new(@pattern_canvas, event){|dc|
      # Fill in onscreen buffer from PPU buffer
      # Note: This has got to be the slowest possible way to do this.
      @pattern_table0_screen_buffer.each_index { |scanline_index|
        scanline = @pattern_table0_screen_buffer[scanline_index]
        scanline.each_index { |pixel_index|
          # Pixel is the RGB (24-bit) color value for this pixel
          # Now do something with it!
          dc.foreground = @pattern_table0_screen_buffer[scanline_index][pixel_index]
          dc.drawPoint(pixel_index,scanline_index)
        }
      }

      @pattern_table1_screen_buffer.each_index { |scanline_index|
        scanline = @pattern_table1_screen_buffer[scanline_index]
        scanline.each_index { |pixel_index|
          # Pixel is the RGB (24-bit) color value for this pixel
          # Now do something with it!
          dc.foreground = @pattern_table1_screen_buffer[scanline_index][pixel_index]
          dc.drawPoint(pixel_index,scanline_index + 128)
        }
      }
    }

    sdc.end
  end
  
  def combine_pattern_table_bytes(byte0, byte1)
    result = Array.new(8, 0)
    result[0] = ((byte0 & 0x80) >> 7) | ((byte1 & 0x80) >> 6)
    result[1] = ((byte0 & 0x40) >> 6) | ((byte1 & 0x40) >> 5)
    result[2] = ((byte0 & 0x20) >> 5) | ((byte1 & 0x20) >> 4)
    result[3] = ((byte0 & 0x10) >> 4) | ((byte1 & 0x10) >> 3)
    result[4] = ((byte0 & 0x08) >> 3) | ((byte1 & 0x08) >> 2)
    result[5] = ((byte0 & 0x04) >> 2) | ((byte1 & 0x04) >> 1)
    result[6] = ((byte0 & 0x02) >> 1) | (byte1 & 0x02)
    result[7] = (byte0 & 0x01) | ((byte1 & 0x01) << 1)
    return result
  end
end