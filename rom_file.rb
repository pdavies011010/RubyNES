require "constants"
class ROMFile
  attr_reader :prg_page_count, :chr_page_count, :mapper
  attr_reader :rom_control_1, :rom_control_2
  attr_reader :prg_rom_pages, :chr_rom_pages
  
  include Constants
  
  
  def initialize(rom_file_path)
    super()
    
    @prg_page_count = 0
    @chr_page_count = 0
    @mapper = 0
    @rom_control_1 = 0
    @rom_control_2 = 0
    
    @prg_rom_pages = nil
    @chr_rom_pages = nil
    
    load_rom_file(rom_file_path)
  end
  
  def load_rom_file(rom_file_path)
    begin
      fd = IO.sysopen(rom_file_path, "rb")
    rescue
      DEBUG.debug_print "Error opening ROM file\n"
      DEBUG.debug_getcommands
      raise
    end
    
    IO.open(fd) { |io|
      filetype = io.read(4) # Should be "NES0x1A"
      @prg_page_count = io.readchar # 16k PRG-ROM Page Count
      @chr_page_count = io.readchar # 8k CHR-ROM Page Count
      @rom_control_1 = io.readchar
      @rom_control_2 = io.readchar
      @mapper = (@rom_control_1 >> 4) | @rom_control_2
      
      io.read(8) # Read in 8 remaining header bytes (unused at the moment)
      
      DEBUG.debug_print "File Type: " + filetype.to_s + "\n"
      DEBUG.debug_print  "PRG-ROM Pages: " + @prg_page_count.to_s + "\n"
      DEBUG.debug_print  "CHR-ROM Pages: " + @chr_page_count.to_s + "\n"
      DEBUG.debug_print  "ROM Control Byte #1: " + @rom_control_1.to_s + "\n"
      DEBUG.debug_print  "ROM Control Byte #2: " + @rom_control_2.to_s + "\n"
      DEBUG.debug_print  "Mapper: " + @mapper.to_s + "\n"
      
      # Load PRG-ROM and CHR-Pages into object variables
      @prg_rom_pages = Array.new(@prg_page_count)
      @chr_rom_pages = Array.new(@chr_page_count)
      
      # Read in data for PRG-ROM pages (@TODO: there's got to be a cleaner way!)
      (0...@prg_page_count).each { |i|
        @prg_rom_pages[i] = Array.new(PRG_ROM_PAGE_SIZE,0)
        (0...PRG_ROM_PAGE_SIZE).each { |j| 
          @prg_rom_pages[i][j] = io.readchar
        }
      }
      
      
      # Read in data for CHR-ROM pages (@TODO: there's got to be a cleaner way!)
      (0...@chr_page_count).each { |i|
        @chr_rom_pages[i] = Array.new(CHR_ROM_PAGE_SIZE,0)
        (0...CHR_ROM_PAGE_SIZE).each { |j| 
          @chr_rom_pages[i][j] = io.readchar
        }
      }
    }
  end
end