require "constants"

# Note, Debugger must be available as a global constant 'DEBUG'

class MMC
  attr_accessor :cpu_ram, :cartridge_ram, :cartridge_bank_low, :cartridge_bank_high
  attr_accessor :pattern_table_0, :pattern_table_1, :name_table_0, :attr_table_0
  attr_accessor :name_table_1, :attr_table_1, :name_table_2, :attr_table_2
  attr_accessor :name_table_3, :attr_table_3, :image_palette, :sprite_palette
  attr_accessor :sprite_mem
  
  # The MMC needs access to the PPU so it can get / set the value of PPU registers
  attr_accessor :ppu
  
  # The MMC needs access to the CPU so it can generate NMI's, etc.
  attr_accessor :cpu
  
  include Constants
  
  public
  def initialize
    super
    
    # Initalize memory maps here
    @cpu_ram = Array.new(CPU_RAM_SIZE, 0) # 2kB ram, fill with 0
    @cartridge_ram = Array.new(CARTRIDGE_RAM_SIZE, 0) # 8kB cartridge ram, fill with 0
    @cartridge_bank_low = Array.new(CARTRIDGE_BANK_SIZE, 0) # 16kB cartridge low bank, fill with 0
    @cartridge_bank_high = Array.new(CARTRIDGE_BANK_SIZE, 0) # 16kB cartridge high bank, fill with 0
    
    @pattern_table_0 = Array.new(PATTERN_TABLE_SIZE, 0) # 4kB pattern table
    @pattern_table_1 = Array.new(PATTERN_TABLE_SIZE, 0) # 4kB pattern table
    @name_table_0 = Array.new(NAME_TABLE_SIZE, 0) #960 Byte name table
    @attr_table_0 = Array.new(ATTRIBUTE_TABLE_SIZE, 0) #64 Byte attribute table
    @name_table_1 = Array.new(NAME_TABLE_SIZE, 0) #960 Byte name table
    @attr_table_1 = Array.new(ATTRIBUTE_TABLE_SIZE, 0) #64 Byte attribute table
    @name_table_2 = Array.new(NAME_TABLE_SIZE, 0) #960 Byte name table
    @attr_table_2 = Array.new(ATTRIBUTE_TABLE_SIZE, 0) #64 Byte attribute table
    @name_table_3 = Array.new(NAME_TABLE_SIZE, 0) #960 Byte name table
    @attr_table_3 = Array.new(ATTRIBUTE_TABLE_SIZE, 0) #64 Byte attribute table
    @image_palette = Array.new(PALETTE_SIZE, 0) # 16 Byte image palette
    @sprite_palette = Array.new(PALETTE_SIZE, 0) # 16 Byte sprite palette
    @sprite_mem = Array.new(SPRITE_MEM_SIZE, 0)  # 256 Byte sprite memory
    
    # Initialize these two toggle switches that affect the way certain PPU ports work
    @screen_scroll_reg_switch = false
    @ppu_mem_address_reg_switch = false
    
    # Add debug commands
    DEBUG.debug_addcommand "getcpumem", Proc.new {|address| DEBUG.debug_print(DEBUG.num2hex(read_cpu_mem(address.hex)) + "\n")}
    DEBUG.debug_addcommand "setcpumem", Proc.new {|param| 
      address = param.split(",")[0]
      value = param.split(",")[1]
      write_cpu_mem(address.hex, value.hex)
    }
    DEBUG.debug_addcommand "getcpumemblock", Proc.new {|params| 
      address0 = params.split(",")[0].hex
      address1 = params.split(",")[1].hex
      
      DEBUG.debug_print("\n#{DEBUG.num2hex(address0)}: ")
      (address0..address1).each { |address|
        if (address % 16 == 0 and address != address0)
          DEBUG.debug_print("\n#{DEBUG.num2hex(address)}: ")
        end
        DEBUG.debug_print(" #{DEBUG.num2hex(read_cpu_mem(address))}")
      }
    }
    
    DEBUG.debug_addcommand "getppumem", Proc.new {|address| DEBUG.debug_print(DEBUG.num2hex(read_ppu_mem(address.hex)) + "\n")}
    DEBUG.debug_addcommand "setppumem", Proc.new {|param| 
      address = param.split(",")[0]
      value = param.split(",")[1]
      write_ppu_mem(address.hex, value.hex)
    }
    DEBUG.debug_addcommand "getppumemblock", Proc.new {|params| 
      address0 = params.split(",")[0].hex
      address1 = params.split(",")[1].hex
      
      DEBUG.debug_print("\n#{DEBUG.num2hex(address0)}: ")
      (address0..address1).each { |address|
        if (address % 16 == 0 and address != address0)
          DEBUG.debug_print("\n#{DEBUG.num2hex(address)}: ")
        end
        DEBUG.debug_print(" #{DEBUG.num2hex(read_ppu_mem(address))}")
      }
    }
    
    DEBUG.debug_addcommand "getspritemem", Proc.new {|address| DEBUG.debug_print(DEBUG.num2hex(@sprite_mem[address.hex]) + "\n")}
    DEBUG.debug_addcommand "setspritemem", Proc.new {|param| 
      address = param.split(",")[0]
      value = param.split(",")[1]
      @sprite_mem[address.hex] = value.hex
    }
    DEBUG.debug_addcommand "getspritememblock", Proc.new {|params| 
      address0 = params.split(",")[0].hex
      address1 = params.split(",")[1].hex
      
      DEBUG.debug_print("\n#{DEBUG.num2hex(address0)}: ")
      (address0..address1).each { |address|
        if (address % 16 == 0 and address != address0)
          DEBUG.debug_print("\n#{DEBUG.num2hex(address)}: ")
        end
        DEBUG.debug_print(" #{DEBUG.num2hex(@sprite_mem[address])}")
      }
    }
  end
  
  # Read / Write CPU Memory
  def read_cpu_mem(address)
    result = 0
    
    if (address >= CPU_RAM_LO and address <= CPU_RAM_HI)
      # Read from CPU RAM
      # Handle mirroring
      ram_mirror = address / CPU_RAM_SIZE
      true_address = address - (CPU_RAM_SIZE * ram_mirror)
      result = @cpu_ram[true_address]
    elsif (address >= IO_LO and address <= IO_HI)
      # Read from IO ports 
      # Handle port mirroring
      if (address <= PPU_PORT_HI)
        # PPU Ports
        port_mirror = (address - PPU_PORT_LO) / PPU_PORT_SIZE
        true_address = address - (PPU_PORT_SIZE * port_mirror)
      else
        # Other Ports (APU mostly)
        port_mirror = (address - OTHER_PORT_LO) / OTHER_PORT_SIZE
        true_address = address - (OTHER_PORT_SIZE * port_mirror)
      end
      
      case true_address
        when PPU_CONTROL_REG_1_PORT
          result = @ppu.control_reg_1
        when PPU_CONTROL_REG_2_PORT
          result = @ppu.control_reg_2
        when PPU_STATUS_REG_PORT
          result = @ppu.status
          @ppu.status &= (~PPU_STAT_VBLANK) # Clear VBLANK flag on read
        when PPU_SPRITE_MEM_DATA_PORT
          result = @sprite_mem[@ppu.sprite_mem_addr]
          @ppu.sprite_mem_addr+=1
        when PPU_MEM_DATA_PORT
          result = read_ppu_mem(@ppu.ppu_mem_addr)

          if (@ppu.vertical_rw_flag_set?)
            @ppu.ppu_mem_addr+=32
          else
            @ppu.ppu_mem_addr+=1
          end
       end
      
    elsif (address >= EXPANSION_MODULES_LO and address <= EXPANSION_MODULES_HI)
      # Read from expansion modules
    elsif (address >= CARTRIDGE_RAM_LO and address <= CARTRIDGE_RAM_HI)
      # Read from cartridge ram
      result = @cartridge_ram[address - CARTRIDGE_RAM_LO]
    elsif (address >= CARTRIDGE_ROM_LOW_BANK_LO and address <= CARTRIDGE_ROM_LOW_BANK_HI)
      # Read from cartridge low bank
      result = @cartridge_bank_low[address - CARTRIDGE_ROM_LOW_BANK_LO]
    elsif (address >= CARTRIDGE_ROM_HIGH_BANK_LO and address <= CARTRIDGE_ROM_HIGH_BANK_HI)
      # Read from cartridge high bank
      result = @cartridge_bank_high[address - CARTRIDGE_ROM_HIGH_BANK_LO]
    end
    
    return result
  end

  def read_cpu_mem_safe(address)
    # This will read from CPU mem without performing any updates to anything (registers specifically)
    result = 0

    if (address >= IO_LO and address <= IO_HI)
      # Read from IO ports
      # Handle port mirroring
      if (address <= PPU_PORT_HI)
        # PPU Ports
        port_mirror = (address - PPU_PORT_LO) / PPU_PORT_SIZE
        true_address = address - (PPU_PORT_SIZE * port_mirror)
      else
        # Other Ports (APU mostly)
        port_mirror = (address - OTHER_PORT_LO) / OTHER_PORT_SIZE
        true_address = address - (OTHER_PORT_SIZE * port_mirror)
      end

      case true_address
        when PPU_CONTROL_REG_1_PORT
          result = @ppu.control_reg_1
        when PPU_CONTROL_REG_2_PORT
          result = @ppu.control_reg_2
        when PPU_STATUS_REG_PORT
          result = @ppu.status
        when PPU_SPRITE_MEM_DATA_PORT
          result = @sprite_mem[@ppu.sprite_mem_addr]
        when PPU_MEM_DATA_PORT
          result = read_ppu_mem(@ppu.ppu_mem_addr)
       end

    else
      result = read_cpu_mem(address)
    end

    return result
  end
  
  def write_cpu_mem(address, value)
    if (address >= CPU_RAM_LO and address <= CPU_RAM_HI)
      # Write into CPU RAM
      # Handle mirroring
      ram_mirror = address / CPU_RAM_SIZE
      true_address = address - (CPU_RAM_SIZE * ram_mirror)
      @cpu_ram[true_address] = value
    elsif (address >= IO_LO and address <= IO_HI)
      # Write into IO ports 
      # Handle port mirroring
      if (address <= PPU_PORT_HI)
        # PPU Ports
        port_mirror = (address - PPU_PORT_LO) / PPU_PORT_SIZE
        true_address = address - (PPU_PORT_SIZE * port_mirror)
      else
        # Other Ports (APU mostly)
        port_mirror = (address - OTHER_PORT_LO) / OTHER_PORT_SIZE
        true_address = address - (OTHER_PORT_SIZE * port_mirror)
      end
      
      case true_address
        when PPU_CONTROL_REG_1_PORT
          @ppu.control_reg_1 = value
        when PPU_CONTROL_REG_2_PORT
          @ppu.control_reg_2 = value
          @ppu.set_background_color # Recalculate background color
        when PPU_SPRITE_MEM_ADDRESS_PORT
          @ppu.sprite_mem_addr = value
        when PPU_SPRITE_MEM_DATA_PORT
          @sprite_mem[@ppu.sprite_mem_addr] = value
          @ppu.sprite_mem_addr+=1
        when PPU_SCREEN_SCROLL_OFFSET_PORT
          if not @screen_scroll_reg_switch
            # Set Vertical Scroll Register
            @ppu.vertical_scroll_reg = value unless value > 239
          else
            # Set Horizontal Scroll Register
            @ppu.horizontal_scroll_reg = value
          end
          # Toggle switch
          @screen_scroll_reg_switch = (not @screen_scroll_reg_switch) ? true : false
        
        when PPU_MEM_ADDRESS_PORT
          if not @ppu_mem_address_reg_switch
            @ppu.ppu_mem_addr = 0  # Reset the PPU memory address register

            # Set high 6 bits of PPU Memory address register
            @ppu.ppu_mem_addr |= ((value & 0x3F) << 8)
          else
            # Set low 8 bits of PPU Memory address register
            @ppu.ppu_mem_addr |= value
          end
          
          # Toggle switch
          @ppu_mem_address_reg_switch = (not @ppu_mem_address_reg_switch) ? true : false
          
        when PPU_MEM_DATA_PORT
          write_ppu_mem(@ppu.ppu_mem_addr, value)
          DEBUG.debug_print "\nWriting #{DEBUG.num2hex(value)} to PPU address #{DEBUG.num2hex(@ppu.ppu_mem_addr)}"
          if (@ppu.vertical_rw_flag_set?)
            @ppu.ppu_mem_addr+=32
          else
            @ppu.ppu_mem_addr+=1
          end
        
        when PPU_SPRITE_DMA_PORT
          # Sprite RAM DMA - Transfer 256 bytes of data from CPU mem to Sprite RAM
          # from location at (0x100 * value)
          start_address = value * 0x100
          end_address = start_address + 0x100
          (start_address...end_address).each {|address|
            @sprite_mem[address - start_address] = read_cpu_mem(address)
          }
       end
      
    elsif (address >= EXPANSION_MODULES_LO and address <= EXPANSION_MODULES_HI)
      # Write into expansion modules
    elsif (address >= CARTRIDGE_RAM_LO and address <= CARTRIDGE_RAM_HI)
      # Write into cartridge ram
      @cartridge_ram[address - CARTRIDGE_RAM_LO] = value
    elsif (address >= CARTRIDGE_ROM_LOW_BANK_LO and address <= CARTRIDGE_ROM_LOW_BANK_HI)
      # Write into cartridge low bank???
      # @cartridge_bank_low[address - CARTRIDGE_ROM_LOW_BANK_LO] = value
    elsif (address >= CARTRIDGE_ROM_HIGH_BANK_LO and address <= CARTRIDGE_ROM_HIGH_BANK_HI)
      # Write into cartridge high bank???
      # @cartridge_bank_high[address - CARTRIDGE_ROM_HIGH_BANK_LO] = value
    end
  end
  
  # Read / Write PPU Memory
  def read_ppu_mem(address)
    result = 0
    
    if (address >= PATTERN_TABLE_0_LO and address <= PATTERN_TABLE_0_HI)
      result = @pattern_table_0[address]
    elsif (address >= PATTERN_TABLE_1_LO and address <= PATTERN_TABLE_1_HI)
      result = @pattern_table_1[address - PATTERN_TABLE_1_LO]
    elsif (address >= NAME_TABLE_0_LO and address <= NAME_TABLE_0_HI)
      result = @name_table_0[address - NAME_TABLE_0_LO]
    elsif (address >= ATTRIBUTE_TABLE_0_LO and address <= ATTRIBUTE_TABLE_0_HI)
      result = @attr_table_0[address - ATTRIBUTE_TABLE_0_LO]
    elsif (address >= NAME_TABLE_1_LO and address <= NAME_TABLE_1_HI)
      result = @name_table_1[address - NAME_TABLE_1_LO]
    elsif (address >= ATTRIBUTE_TABLE_1_LO and address <= ATTRIBUTE_TABLE_1_HI)
      result = @attr_table_1[address - ATTRIBUTE_TABLE_1_LO]
    elsif (address >= NAME_TABLE_2_LO and address <= NAME_TABLE_2_HI)
      result = @name_table_2[address - NAME_TABLE_2_LO]
    elsif (address >= ATTRIBUTE_TABLE_2_LO and address <= ATTRIBUTE_TABLE_2_HI)
      result = @attr_table_2[address - ATTRIBUTE_TABLE_2_LO]
    elsif (address >= NAME_TABLE_3_LO and address <= NAME_TABLE_3_HI)
      result = @name_table_3[address - NAME_TABLE_3_LO]
    elsif (address >= ATTRIBUTE_TABLE_3_LO and address <= ATTRIBUTE_TABLE_3_HI)
      result = @attr_table_3[address - ATTRIBUTE_TABLE_3_LO]
    elsif (address >= IMAGE_PALETTE_LO and address <= IMAGE_PALETTE_HI)
      result = @image_palette[address - IMAGE_PALETTE_LO]
    elsif (address >= SPRITE_PALETTE_LO and address <= SPRITE_PALETTE_HI)
      result = @sprite_palette[address - SPRITE_PALETTE_LO]
    end
    
    return result.to_i
  end
  
  def write_ppu_mem(address, value)
    if (address >= PATTERN_TABLE_0_LO and address <= PATTERN_TABLE_0_HI)
      @pattern_table_0[address] = value
    elsif (address >= PATTERN_TABLE_1_LO and address <= PATTERN_TABLE_1_HI)
      @pattern_table_1[address - PATTERN_TABLE_1_LO] = value
    elsif (address >= NAME_TABLE_0_LO and address <= NAME_TABLE_0_HI)
      @name_table_0[address - NAME_TABLE_0_LO] = value
    elsif (address >= ATTRIBUTE_TABLE_0_LO and address <= ATTRIBUTE_TABLE_0_HI)
      @attr_table_0[address - ATTRIBUTE_TABLE_0_LO] = value
    elsif (address >= NAME_TABLE_1_LO and address <= NAME_TABLE_1_HI)
      @name_table_1[address - NAME_TABLE_1_LO] = value
    elsif (address >= ATTRIBUTE_TABLE_1_LO and address <= ATTRIBUTE_TABLE_1_HI)
      @attr_table_1[address - ATTRIBUTE_TABLE_1_LO] = value
    elsif (address >= NAME_TABLE_2_LO and address <= NAME_TABLE_2_HI)
      @name_table_2[address - NAME_TABLE_2_LO] = value
    elsif (address >= ATTRIBUTE_TABLE_2_LO and address <= ATTRIBUTE_TABLE_2_HI)
      @attr_table_2[address - ATTRIBUTE_TABLE_2_LO] = value
    elsif (address >= NAME_TABLE_3_LO and address <= NAME_TABLE_3_HI)
      @name_table_3[address - NAME_TABLE_3_LO] = value
    elsif (address >= ATTRIBUTE_TABLE_3_LO and address <= ATTRIBUTE_TABLE_3_HI)
      @attr_table_3[address - ATTRIBUTE_TABLE_3_LO] = value
    elsif (address >= IMAGE_PALETTE_LO and address <= IMAGE_PALETTE_HI)
      @image_palette[address - IMAGE_PALETTE_LO] = value
    elsif (address >= SPRITE_PALETTE_LO and address <= SPRITE_PALETTE_HI)
      @sprite_palette[address - SPRITE_PALETTE_LO] = value
    end
  end
  
end