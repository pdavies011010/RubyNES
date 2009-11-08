require "rubygems"
gem "ruby-processing"
require "ruby-processing"
require "nes"
require "debugger"
require "palette"
require "constants"
require "socket"

include_class "javax.swing.JFileChooser"
include_class "java.lang.System"

module Processing
  SKETCH_PATH = "./"
end

class Main < Processing::App
  
  attr_accessor :nes
  
  include Palette
  include Constants

  # Game Canvas Area
  CANVAS_X=100
  CANVAS_Y=0
  CANVAS_W=256
  CANVAS_H=241

  # Buttons
  BTN_PANEL_W=100
  BTN_PANEL_H=300
  
  CHECKBOX_LABEL_FONT="Monospaced.bold"
  CHECKBOX_LABEL_SIZE=13
  CHECKBOX_UNCHECKED_IMG="icons/checkbox-unchecked.jpg"
  CHECKBOX_CHECKED_IMG="icons/checkbox-checked.jpg"

  LOAD_BTN_X=5
  LOAD_BTN_Y=10
  LOAD_BTN_H=90
  LOAD_BTN_W=90
  LOAD_BTN_IMG="icons/load.jpg"

  PWR_BTN_X=10
  PWR_BTN_Y=105
  PWR_BTN_H=40
  PWR_BTN_W=80
  PWR_BTN_IMG="icons/power.jpg"

  RESET_BTN_X=10
  RESET_BTN_Y=150
  RESET_BTN_H=40
  RESET_BTN_W=80
  RESET_BTN_IMG="icons/reset.jpg"

  LOGO_X=101
  LOGO_Y=250
  LOGO_W=256
  LOGO_H=40
  LOGO_IMG="icons/logo.jpg"

  BOTTOM_PANEL_X=100
  BOTTOM_PANEL_Y=241
  BOTTOM_PANEL_W=256
  BOTTOM_PANEL_H=59
  
  DEBUG_LABEL="Debug?"
  DEBUG_LABEL_X=5
  DEBUG_LABEL_Y=215

  DEBUG_BTN_X=78
  DEBUG_BTN_Y=200
  DEBUG_BTN_W=20
  DEBUG_BTN_H=20

  PALETTE_LABEL="Show \nPalette?"
  PALETTE_LABEL_X=5
  PALETTE_LABEL_Y=240

  PALETTE_BTN_X=78
  PALETTE_BTN_Y=232
  PALETTE_BTN_W=20
  PALETTE_BTN_H=20

  PTABLE_LABEL="Show \nP.Tables?"
  PTABLE_LABEL_X=5
  PTABLE_LABEL_Y=275

  PTABLE_BTN_X=78
  PTABLE_BTN_Y=270
  PTABLE_BTN_W=20
  PTABLE_BTN_H=20

  # Palette Viewer Canvas Area
  PALETTE_VIEWER_X=101
  PALETTE_VIEWER_Y=250
  PALETTE_VIEWER_W=256
  PALETTE_VIEWER_H=32

  # Pattern Table Canvas Area
  PATTERN_TABLE_VIEWER_X=101
  PATTERN_TABLE_VIEWER_Y=0
  PATTERN_TABLE_VIEWER_W=128
  PATTERN_TABLE_VIEWER_H=256
  

  def setup
    @title = "RubyNES"

    @palette_viewer_shown = false
    @palette_viewer = nil

    @pattern_table_viewer_shown = false
    @pattern_table_viewer = nil

    @paused = false
    
    size 356, 300, P2D

    # Bottom Panel
    fill 0xFF, 0xFF, 0xFF
    rect BOTTOM_PANEL_X, BOTTOM_PANEL_Y, BOTTOM_PANEL_W, BOTTOM_PANEL_H

    # Control Panel
    fill 0xAA, 0xAA, 0xAA
    rect 0, 0, BTN_PANEL_W, BTN_PANEL_H
    
    # Logo
    logo = loadImage LOGO_IMG
    image logo, LOGO_X, LOGO_Y, LOGO_W, LOGO_H

    # Load Buton
    load = loadImage LOAD_BTN_IMG
    image load, LOAD_BTN_X, LOAD_BTN_Y, LOAD_BTN_W, LOAD_BTN_H

    # Power Button
    power = loadImage PWR_BTN_IMG
    image power, PWR_BTN_X, PWR_BTN_Y, PWR_BTN_W, PWR_BTN_H

    # Reset Button
    reset = loadImage RESET_BTN_IMG
    image reset, RESET_BTN_X, RESET_BTN_Y, RESET_BTN_W, RESET_BTN_H

    # List all fonts
    #fontList = PFont.list
    #fontList.each {|font| STDOUT.puts "\n" + font}

    checkbox_font = createFont CHECKBOX_LABEL_FONT, CHECKBOX_LABEL_SIZE

    # Debugging Checkbox
    debug = loadImage DEBUG.is_debugging? ? CHECKBOX_CHECKED_IMG : CHECKBOX_UNCHECKED_IMG
    image debug, DEBUG_BTN_X, DEBUG_BTN_Y, DEBUG_BTN_W, DEBUG_BTN_H
    fill 0, 0, 0
    textFont checkbox_font
    text DEBUG_LABEL, DEBUG_LABEL_X, DEBUG_LABEL_Y
    
    # Palette Viewer Checkbox
    palette = loadImage @palette_viewer_shown ? CHECKBOX_CHECKED_IMG : CHECKBOX_UNCHECKED_IMG
    image palette, PALETTE_BTN_X, PALETTE_BTN_Y, PALETTE_BTN_W, PALETTE_BTN_H
    fill 0, 0, 0
    textFont checkbox_font
    text PALETTE_LABEL, PALETTE_LABEL_X, PALETTE_LABEL_Y

    # Pattern Table Viewer Checkbox
    ptable = loadImage @pattern_table_viewer_shown ? CHECKBOX_CHECKED_IMG : CHECKBOX_UNCHECKED_IMG
    image ptable, PTABLE_BTN_X, PTABLE_BTN_Y, PTABLE_BTN_W, PTABLE_BTN_H
    fill 0, 0, 0
    textFont checkbox_font
    text PTABLE_LABEL, PTABLE_LABEL_X, PTABLE_LABEL_Y

    
    # Now initialize the actual NES emulator
    @nes = NES.new

    # NTSC refresh rate (Should Be) 1/30 of a second
    frameRate 30

    cpu_thread = Thread.new {
      # Since we have a non-blocking thread here, let's set up the receiving socket for our debugger
      server = TCPServer.new("localhost", 6502)
      socket = server.accept
      DEBUG.io_reader = socket
    }

    @debug_writer = TCPSocket.new( "localhost", 6502 )
    
  end

  def pause
    @paused = true
    update_titlebar_status "* Paused *"
  end

  def unpause
    @paused = false
    update_titlebar_status "Running"
  end
  
  def draw
    if (@pattern_table_viewer_shown)
      pt_img = createImage(PATTERN_TABLE_VIEWER_W, PATTERN_TABLE_VIEWER_H, RGB)
      @pattern_table_viewer.repaint(pt_img)
      image pt_img, PATTERN_TABLE_VIEWER_X, PATTERN_TABLE_VIEWER_Y, PATTERN_TABLE_VIEWER_W, PATTERN_TABLE_VIEWER_H
      
    else
      if @nes.is_power_on? and not @paused
        @nes.run_one_frame
        repaint

        if @palette_viewer_shown
          pal_img = createImage(PALETTE_VIEWER_W, PALETTE_VIEWER_H, RGB)
          @palette_viewer.repaint(pal_img)
          image pal_img, PALETTE_VIEWER_X, PALETTE_VIEWER_Y, PALETTE_VIEWER_W, PALETTE_VIEWER_H
        end
      end
    end
  end
  
  def repaint
    ppu = @nes.ppu

    img = createImage(CANVAS_W, CANVAS_H, RGB)
    img.loadPixels
    ppu.screen_buffer.each_index { |scanline_index|
      if (scanline_index != 0) # Scanline 1 in the ppu is a dummy scanline (nothing drawn)
        scanline = ppu.screen_buffer[scanline_index]
        scanline.each_index { |pixel_index|
          pixel = COLORS[scanline[pixel_index]]
          img.pixels[((scanline_index - 1) * 256) + pixel_index] = color(((pixel & 0xFF0000) >> 16), ((pixel & 0xFF00) >> 8), (pixel & 0xFF)) #
        }
      end
    }
    img.updatePixels

    image img,CANVAS_X, CANVAS_Y, CANVAS_W, CANVAS_H
  end

  def mousePressed
    x = mouseX
    y = mouseY

    load_button_handler x, y
    power_button_handler x, y
    reset_button_handler x, y
    debug_button_handler x, y
    palette_button_handler x, y
    pattern_table_button_handler x, y
  end

  def keyPressed
    @debug_buffer = "" if @debug_buffer.nil?
    mmc = @nes.mmc

    # @TODO: Put in handling for second joystick
    if (["A","S","Z","X"].include?(key))
      case key
      when "A"
        mmc.joystick_1_keys |= JOYSTICK_B
      when "S"
        mmc.joystick_1_keys |= JOYSTICK_A
      when "Z"
        mmc.joystick_1_keys |= JOYSTICK_SELECT
      when "X"
        mmc.joystick_1_keys |= JOYSTICK_START
      end
    elsif (key == CODED)
      case keyCode
      when UP
        mmc.joystick_1_keys |= JOYSTICK_UP
      when DOWN
        mmc.joystick_1_keys |= JOYSTICK_DOWN
      when LEFT
        mmc.joystick_1_keys |= JOYSTICK_LEFT
      when RIGHT
        mmc.joystick_1_keys |= JOYSTICK_RIGHT
      end
    elsif (key.respond_to? :chop)
      DEBUG.debug_print key
      @debug_buffer << key
    end

    if (key == "\n")
      @debug_writer.puts @debug_buffer
      @debug_buffer = ""
    end
  end

  def load_button_handler(x, y)
    return unless (LOAD_BTN_X..(LOAD_BTN_X + LOAD_BTN_W)).include? x
    return unless (LOAD_BTN_Y..(LOAD_BTN_Y + LOAD_BTN_H)).include? y

    c = JFileChooser.new(java.io.File.new(Dir.pwd))

    Thread.new {
      rVal = c.showOpenDialog(MAIN.frame)
      if (rVal == JFileChooser::APPROVE_OPTION)
        rom_file = c.getSelectedFile # Returns a Java File
        file = rom_file.getAbsolutePath
        if file != nil and not file.empty?
          MAIN.frame.setTitle "RubyNES (#{rom_file.getName})"
          MAIN.nes.load_rom file
        end
      end
    }

  end

  def power_button_handler(x, y)
    return unless (PWR_BTN_X..(PWR_BTN_X + PWR_BTN_W)).include? x
    return unless (PWR_BTN_Y..(PWR_BTN_Y + PWR_BTN_H)).include? y

    Thread.new {
      MAIN.nes.power_on if MAIN.nes.rom_file_path != nil and not MAIN.nes.rom_file_path.empty?
    }
    update_titlebar_status "Running"
  end

  def reset_button_handler(x, y)
    return unless (RESET_BTN_X..(RESET_BTN_X + RESET_BTN_W)).include? x
    return unless (RESET_BTN_Y..(RESET_BTN_Y + RESET_BTN_H)).include? y
    update_titlebar_status "Running"

    Thread.new {
      MAIN.nes.cpu.reset
    }
  end

  def debug_button_handler(x, y)
    return unless (DEBUG_BTN_X..(DEBUG_BTN_X + DEBUG_BTN_W)).include? x
    return unless (DEBUG_BTN_Y..(DEBUG_BTN_Y + DEBUG_BTN_H)).include? y

    if not DEBUG.is_debugging?
      DEBUG.enable_debugging
      debug = loadImage CHECKBOX_CHECKED_IMG
      image debug, DEBUG_BTN_X, DEBUG_BTN_Y, DEBUG_BTN_W, DEBUG_BTN_H
    else
      DEBUG.disable_debugging
      debug = loadImage CHECKBOX_UNCHECKED_IMG
      image debug, DEBUG_BTN_X, DEBUG_BTN_Y, DEBUG_BTN_W, DEBUG_BTN_H
    end
  end
  
  def palette_button_handler(x, y)
    return unless (PALETTE_BTN_X..(PALETTE_BTN_X + PALETTE_BTN_W)).include? x
    return unless (PALETTE_BTN_Y..(PALETTE_BTN_Y + PALETTE_BTN_H)).include? y

    if not @palette_viewer_shown
      @palette_viewer_shown = true
      @palette_viewer = PaletteViewer.new(@nes)

      palette = loadImage CHECKBOX_CHECKED_IMG
      image palette, PALETTE_BTN_X, PALETTE_BTN_Y, PALETTE_BTN_W, PALETTE_BTN_H
    else
      @palette_viewer_shown = false
      @palette_viewer = nil
      
      palette = loadImage CHECKBOX_UNCHECKED_IMG
      image palette, PALETTE_BTN_X, PALETTE_BTN_Y, PALETTE_BTN_W, PALETTE_BTN_H

      # Replace the Logo
      logo = loadImage LOGO_IMG
      image logo, LOGO_X, LOGO_Y, LOGO_W, LOGO_H
    end
  end


  def pattern_table_button_handler(x, y)
    return unless (PTABLE_BTN_X..(PTABLE_BTN_X + PTABLE_BTN_W)).include? x
    return unless (PTABLE_BTN_Y..(PTABLE_BTN_Y + PTABLE_BTN_H)).include? y

    if (@nes.is_power_on?)
      if not @pattern_table_viewer_shown
        pause
        @pattern_table_viewer_shown = true
        @pattern_table_viewer = PatternTablesViewer.new(@nes)

        ptable = loadImage CHECKBOX_CHECKED_IMG
        image ptable, PTABLE_BTN_X, PTABLE_BTN_Y, PTABLE_BTN_W, PTABLE_BTN_H
      else
        unpause
        @pattern_table_viewer_shown = false
        @pattern_table_viewer = nil

        ptable = loadImage CHECKBOX_UNCHECKED_IMG
        image ptable, PTABLE_BTN_X, PTABLE_BTN_Y, PTABLE_BTN_W, PTABLE_BTN_H
      end
    end
  end
  
  def update_titlebar_status(status)
    MAIN.frame.setTitle(MAIN.frame.getTitle.split(" - ")[0] + " - " + status)
  end

end

# Class to enable the palette viewer functionality
class PaletteViewer

  include Palette
  include Constants

  def initialize(nes)
    super()

    @nes = nes
  end

  def repaint(img)

    ppu = @nes.ppu
    mmc = ppu.mmc

    palette = Array.new(32, 0)
    (IMAGE_PALETTE_LO..SPRITE_PALETTE_HI).each {|address| palette[address - IMAGE_PALETTE_LO] = mmc.read_ppu_mem(address) }


    colors = palette.map { |palette_entry|
      col = COLORS[palette_entry]
      MAIN.color((col & 0xFF0000) >> 16, (col & 0xFF00) >> 8, (col & 0xFF))
    }

    img.loadPixels
    colors.each_index {|index|
      x_offset = (index % 16) * 16
      y_offset = (index / 16) * 16
      (0...16).each {|y|
        (0...16).each {|x|
          img.pixels[((y_offset + y) * 256) + (x_offset + x)] = colors[index]
        }
      }
    }
    img.updatePixels
  end
end

# Class to enable the pattern table viewer functionality
class PatternTablesViewer

  include Palette
  include Constants

  def initialize(nes)
    super()

    @nes = nes
  end

  def repaint(img)

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

    img.loadPixels
    pattern_table0_palette_buffer.each_index { |scanline|
      line = pattern_table0_palette_buffer[scanline]
      line.each_index { |pixel|
        # At the moment, not indexing into the image palette, since it doesn't seem to be initializing correctly
        dot = COLORS[line[pixel]]
        img.pixels[(scanline * 128) + pixel] = MAIN.color((dot & 0xFF0000) >> 16, (dot & 0xFF00) >> 8, (dot & 0xFF))
      }
    }

    pattern_table1_palette_buffer.each_index { |scanline|
      line = pattern_table1_palette_buffer[scanline]
      line.each_index { |pixel|
        # At the moment, not indexing into the image palette, since it doesn't seem to be initializing correctly
        dot = COLORS[line[pixel]]
        img.pixels[((scanline + 128) * 128) + pixel] = MAIN.color((dot & 0xFF0000) >> 16, (dot & 0xFF00) >> 8, (dot & 0xFF))
      }
    }
    img.updatePixels

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

