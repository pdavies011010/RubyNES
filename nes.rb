require "constants"
require "mmc"
require "cpu"
require "ppu"
require "rom_file"
require "nes_helper"

# Note, Debugger must be available as a global constant 'DEBUG'

# @TODO: This is waaay too slow. VBLANKS should be occurring on the order of 30 times per second, 
# whereas right now they are happening about 2 per second. 
class NES
  attr_accessor :mmc, :cpu, :ppu, :rom_file_path
  attr_reader :rom_file
  
  include Constants
  
  public 
  def initialize()
    super()
    
    @rom_file = nil
    @powered_on = false
    
    # Add debug commands
    DEBUG.debug_addcommand "loadrom", Proc.new {|rom_file_path| load_rom rom_file_path }
    DEBUG.debug_addcommand "poweron", Proc.new {|param| power_on }
    DEBUG.debug_addcommand "reset", Proc.new {|param| reset }
    DEBUG.debug_addcommand "stopdebugging", Proc.new {|param| disable_debugging }
    DEBUG.debug_addcommand "executecode", Proc.new {|code| print(eval(code)) } 
    DEBUG.debug_addcommand "quit", Proc.new {|param| exit }
  end
  
  def load_rom(rom_file_path)
    # Simply store the passed in rom file path
    @rom_file_path = rom_file_path
  end
  
  def power_on
    # Initalize NES hardware here
    @mmc = MMC.new
    @cpu = CPU.new(@mmc)
    @ppu = PPU.new(@mmc)
    
    # The MMC needs access to the PPU to allow get/set of registers via IO ports
    @mmc.ppu = @ppu  
    
    # The MMC needs access to the CPU to allow it to generate NMI's, etc.
    @mmc.cpu = @cpu
    
    # Load up ROM
    @rom_file = ROMFile.new(@rom_file_path)

    @ppu.name_table_mirroring = @rom_file.mirroring
    
    if @ppu.name_table_mirroring == 0
      # Horizontal Mirroring
      @mmc.name_table_1 = @mmc.name_table_0
      @mmc.name_table_3 = @mmc.name_table_2
    elsif @ppu.name_table_mirroring == 1
      # Vertical Mirroring
      @mmc.name_table_2 = @mmc.name_table_0
      @mmc.name_table_3 = @mmc.name_table_1
    end

    # Get PRG / CHR rom pages from ROMFile object into NES Memory map
    # Note, this depends on the mapper in use ... 
    # @TODO: For now we will assume Mapper #0 !!!. In the future we will need to
    # implement mapper functionality here, as well as during runtime
    if @rom_file.mapper == 0
      if @rom_file.prg_page_count == 1
        @mmc.cartridge_bank_low = @mmc.cartridge_bank_high = @rom_file.prg_rom_pages[0]
      else
        @mmc.cartridge_bank_low = @rom_file.prg_rom_pages[0]
        @mmc.cartridge_bank_high = @rom_file.prg_rom_pages[1]
      end
      
      #Mapper 0 games should always have 1 8Kb CHR-ROM page to map into the pattern tables
      @mmc.pattern_table_0 = NESHelper.split_array(@rom_file.chr_rom_pages[0])[0]
      @mmc.pattern_table_1 = NESHelper.split_array(@rom_file.chr_rom_pages[0])[1]
      @mmc.set_pattern_table_0_writable(false)
      @mmc.set_pattern_table_1_writable(false)
    end
    
    # Reset CPU
    @cpu.reset
    
    # Get debug commands if debugging is enabled
    DEBUG.debug_getcommands
    
    @powered_on = true
  end
  
  def run_one_frame
    @ppu.pre_frame
    
    until @ppu.frame_complete
      
      cycles = @cpu.execute
      
      # CPU CC = PPU CC / 3
      @ppu.execute(cycles * 3)
    end
  
    # Reset PPU Frame complete flag
    @ppu.frame_complete = false
  end
  
  def set_buttons_pressed(buttons_pressed)
    # @TODO: Define buttons
    # This method receives an array of which controller buttons are pressed.
    # Should probably be updated every frame
  end
  
  def is_power_on?
    return @powered_on
  end
  
end