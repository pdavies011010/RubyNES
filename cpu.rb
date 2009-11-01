require "constants"
require "operation"
require "addressing_mode"
require "cpu_tables"

# Note, Debugger must be available as a global constant 'DEBUG'

class CPU
  attr_accessor :mmc, :sp, :pc, :flags, :a, :x, :y
  attr_reader :page_boundary_crossed
  
  include Constants
  include CpuTables
  include AddressingMode
  
  public
  def initialize(mmc)
    super()
    
    # Initalize cpu here
    @mmc = mmc
    @sp = 0 # CPU is not responsible for initializing the stack
    @pc = (@mmc.read_cpu_mem(RESET_HI) << 8) + @mmc.read_cpu_mem(RESET_LO) # Start PC at reset vector
    
    #Initialize registers
    @a = 0
    @x = 0
    @y = 0
    @flags = 0b00100000  # All but the unused flag are cleared to 0
    
    # Debug stuff
    @breakpoints = []
    @step = false
    @log_cpu_state = false
    @debug_read = false
    
    # Add debug commands
    DEBUG.debug_addcommand "go", Proc.new {|param| @step = false}
    DEBUG.debug_addcommand "step", Proc.new {|param| @step = true}
    DEBUG.debug_addcommand "setbreakpoint", Proc.new {|value| @breakpoints[value.hex] = true}
    DEBUG.debug_addcommand "clearbreakpoint", Proc.new {|value| @breakpoints[value.hex] = false}
    DEBUG.debug_addcommand "clearbreakpoints", Proc.new {|param| @breakpoints.each_index {|index| @breakpoints[index] = false }}
    
    DEBUG.debug_addcommand "getstackpointer", Proc.new {|param| DEBUG.debug_print(DEBUG.num2hex(@sp) + "\n")}
    DEBUG.debug_addcommand "getprogramcounter", Proc.new {|param| DEBUG.debug_print(DEBUG.num2hex(@pc) + "\n")}
    DEBUG.debug_addcommand "getprocessorstatus", Proc.new {|param| DEBUG.debug_print(DEBUG.num2hex(@flags) + "\n")}
    DEBUG.debug_addcommand "getaccumulator", Proc.new {|param| DEBUG.debug_print(DEBUG.num2hex(@a) + "\n")}
    DEBUG.debug_addcommand "getx", Proc.new {|param| DEBUG.debug_print(DEBUG.num2hex(@x) + "\n")}
    DEBUG.debug_addcommand "gety", Proc.new {|param| DEBUG.debug_print(DEBUG.num2hex(@y) + "\n")}
    DEBUG.debug_addcommand "setstackpointer", Proc.new {|value| @sp = value.hex }
    DEBUG.debug_addcommand "setprogramcounter", Proc.new {|value| @pc = value.hex }
    DEBUG.debug_addcommand "setprocessorstatus", Proc.new {|value| @flags = value.hex }
    DEBUG.debug_addcommand "setaccumulator", Proc.new {|value| @a = value.hex }
    DEBUG.debug_addcommand "setx", Proc.new {|value| @x = value.hex }
    DEBUG.debug_addcommand "sety", Proc.new {|value| @y = value.hex }
    DEBUG.debug_addcommand "getcpustate", Proc.new {|params| 
      opcode = @mmc.read_cpu_mem(@pc)
      operation = OPERATIONS[opcode]
      addressing_mode = ADDRESSING_MODES[opcode]
      
      # Address and Data have to be passed in, because reading from the mem map can change what's in memory
      address = params.split(",")[0].to_i
      data = params.split(",")[1].to_i
      
      DEBUG.debug_print "Operation: #{Operation.name(operation)} Addressing Mode: #{AddressingMode.name(addressing_mode)} Address: #{DEBUG.num2hex(address)} Data: #{DEBUG.num2hex(data)}\n"
      DEBUG.debug_print "PC: " + DEBUG.num2hex(@pc) + " SP: " + DEBUG.num2hex(@sp) + " A: " + DEBUG.num2hex(@a) + " X: " + DEBUG.num2hex(@x) + " Y: " + DEBUG.num2hex(@y) + "\n"
      DEBUG.debug_print "Status: S-#{sign_flag_set? ? 1 : 0} V-#{overflow_flag_set? ? 1 : 0} B-#{break_flag_set? ? 1 : 0} D-#{decimal_flag_set? ? 1 : 0} I-#{interrupt_flag_set? ? 1 : 0} Z-#{zero_flag_set? ? 1 : 0} C-#{carry_flag_set? ? 1 : 0}\n"
    }
    DEBUG.debug_addcommand "logcpustate", Proc.new {|params| 
      opcode = @mmc.read_cpu_mem(@pc)
      operation = OPERATIONS[opcode]
      addressing_mode = ADDRESSING_MODES[opcode]
      
      # Address and Data have to be passed in, because reading from the mem map can change what's in memory
      address = params.split(",")[0].to_i
      data = params.split(",")[1].to_i
      
      DEBUG.debug_log "Operation: #{Operation.name(operation)} Addressing Mode: #{AddressingMode.name(addressing_mode)} Address: #{DEBUG.num2hex(address)} Data: #{DEBUG.num2hex(data)}\n"
      DEBUG.debug_log "PC: " + DEBUG.num2hex(@pc) + " SP: " + DEBUG.num2hex(@sp) + " A: " + DEBUG.num2hex(@a) + " X: " + DEBUG.num2hex(@x) + " Y: " + DEBUG.num2hex(@y) + "\n"
      DEBUG.debug_log "Status: S-#{sign_flag_set? ? 1 : 0} V-#{overflow_flag_set? ? 1 : 0} B-#{break_flag_set? ? 1 : 0} D-#{decimal_flag_set? ? 1 : 0} I-#{interrupt_flag_set? ? 1 : 0} Z-#{zero_flag_set? ? 1 : 0} C-#{carry_flag_set? ? 1 : 0}\n"
    }
    DEBUG.debug_addcommand "enablecpulogging", Proc.new {|param| @log_cpu_state = true}
    DEBUG.debug_addcommand "disablecpulogging", Proc.new {|param| @log_cpu_state = false}
  end
  
  def reset
    # Reset - load PC with with appropriate location from reset vector
    address = (@mmc.read_cpu_mem(RESET_HI) << 8) | @mmc.read_cpu_mem(RESET_LO)
    @pc = address
    
    DEBUG.debug_print "Reset.\n"
    DEBUG.debug_log "Reset.\n" if (@log_cpu_state)
  end
  
  def nmi
    # Non-Maskable interrupt - Load the PC with the appropraite location from the NMI vector
    # First prepare the CPU
    push((@pc >> 8) & 0xFF)  # Push program counter on stack, high byte first
    push(@pc & 0xFF)
    push(@flags)  #Push status register on the stack
    
    @pc = (@mmc.read_cpu_mem(NMIB_HI) << 8) | @mmc.read_cpu_mem(NMIB_LO)
    
    DEBUG.debug_print "NMI.\n"
    DEBUG.debug_log "NMI.\n" if (@log_cpu_state)
  end
  
  def execute
    # Execute a single instruction and return cycle count
    opcode = @mmc.read_cpu_mem(@pc)
    operation = OPERATIONS[opcode]
    addressing_mode = ADDRESSING_MODES[opcode]
    
    # Note!!! - We are only calculating this for the addressing modes for which
    # it actually matters in terms of cycle counting, namely AbsX, AbsY, IndY and Rel
    @page_boundary_crossed = false
    cycle_offset = 0
    
    address = get_instruction_address(operation, addressing_mode)
    
    # Handle debugging stuff
    if (@step or @breakpoints[@pc])
      # Write out CPU state to screen or log
      @debug_read = true
      debug_data = get_instruction_data(operation, addressing_mode)

      DEBUG.debug_print "Breakpoint Hit.\n" if @breakpoints[@pc]
      DEBUG.debug_execcommand "getcpustate", "#{address},#{debug_data}"
      DEBUG.debug_getcommands
    end
    
    # Perform logging if enabled
    if (@log_cpu_state)
      @debug_read = true
      debug_data = get_instruction_data(operation, addressing_mode)
      DEBUG.debug_execcommand "logcpustate", "#{address},#{debug_data}"
    end

    # Disable debug reading (reads will affect registers, etc.)
    @debug_read = false
    
    case operation
      when Operation::ADC   #ADC
      data = get_instruction_data(operation, addressing_mode)
      
      temp = data + @a + (carry_flag_set? ? 1 : 0)
      calc_zero_flag(temp)
      
      # Note, most of the following logic comes directly from the VICE emulator. 
      # Need to understand it better.
      if decimal_flag_set?
        if (((@a & 0xf) + (src & 0xf) + (carry_flag_set? ? 1 : 0)) > 9) 
          temp += 6
        end
        
        calc_sign_flag(temp)
        set_overflow_flag(!((@a ^ data) & 0x80) && ((@a ^ temp) & 0x80))  
        
        if (temp > 0x99) 
          temp += 96
        end
        
        set_carry_flag(temp > 0x99)
      else
        calc_sign_flag(temp)
        set_overflow_flag(!((@a ^ data) & 0x80) && ((@a ^ temp) & 0x80)) 
        set_carry_flag(temp > 0xFF)
      end
      
      @a = (temp & 0xFF)  # Reduce to 1-byte data
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      cycle_offset = 1 if @page_boundary_crossed
      
      when Operation::AND  #AND
      data = get_instruction_data(operation, addressing_mode)

      temp = (data & @a)
      calc_zero_flag(temp)
      calc_sign_flag(temp)
      @a = temp
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      cycle_offset = 1 if @page_boundary_crossed
      
      when Operation::ASL  #ASL
      data = get_instruction_data(operation, addressing_mode)

      set_carry_flag((data & 0x80) != 0)
      data <<= 1
      data &= 0xFF # Reduce to 1-byte data
      calc_zero_flag(data)
      calc_sign_flag(data)
      if addressing_mode == ACCUMULATOR
        @a = data
      else
        @mmc.write_cpu_mem(address, data)
      end
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::BCC  #BCC
      if not carry_flag_set?
        @pc = address 
      end
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::BCS  #BCS
      if carry_flag_set?
        @pc = address
        
        cycle_offset = @page_boundary_crossed ? 2 : 1
      end
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::BEQ  #BEQ
      if zero_flag_set?
        @pc = address 
        
        cycle_offset = @page_boundary_crossed ? 2 : 1
      end
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::BIT  #BIT
      data = get_instruction_data(operation, addressing_mode)

      calc_sign_flag(data)
      set_overflow_flag((data & 0x40) != 0)
      calc_zero_flag(data & @a)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::BMI  #BMI
      if sign_flag_set?
        @pc = address 
        
        cycle_offset = @page_boundary_crossed ? 2 : 1
      end
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::BNE  #BNE
      if not zero_flag_set?
        @pc = address
        
        cycle_offset = @page_boundary_crossed ? 2 : 1
      end
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::BPL  #BPL
      if not sign_flag_set?
        @pc = address 
        
        cycle_offset = @page_boundary_crossed ? 2 : 1
      end
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::BRK  #BRK
      @pc += 1
      push((@pc >> 8) & 0xFF)  # Push program counter on stack, high byte first
      push(@pc & 0xFF)
      
      set_break_flag(true)  # Set break flag then push status register on stack
      push(@flags)
      
      address = (@mmc.read_cpu_mem(IRQ_BRK_HI) << 8) + @mmc.read_cpu_mem(IRQ_BRK_LO)
      @pc = address
      
      set_interrupt_flag(true) # Lastly set the interrupt disable flag
      
      when Operation::BVC  #BVC
      if not overflow_flag_set?
        @pc = address
        
        cycle_offset = @page_boundary_crossed ? 2 : 1
      end
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::BVS  #BVS
      if overflow_flag_set?
        @pc = address
        
        cycle_offset = @page_boundary_crossed ? 2 : 1
      end
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::CLC  #CLC
      set_carry_flag(false)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::CLD  #CLD
      set_decimal_flag(false)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::CLI  #CLI
      set_interrupt_flag(false)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::CLV  #CLV
      set_overflow_flag(false)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::CMP  #CMP
      data = get_instruction_data(operation, addressing_mode)

      temp = @a - data
      set_carry_flag(temp < 0x100)
      calc_sign_flag(temp)
      calc_zero_flag(temp)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      cycle_offset = 1 if @page_boundary_crossed
      
      when Operation::CPX  #CPX
      data = get_instruction_data(operation, addressing_mode)

      temp = @x - data
      set_carry_flag(temp < 0x100)
      calc_sign_flag(temp)
      calc_zero_flag(temp)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::CPY  #CPY
      data = get_instruction_data(operation, addressing_mode)

      temp = @y - data
      set_carry_flag(temp < 0x100)
      calc_sign_flag(temp)
      calc_zero_flag(temp)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::DEC  #DEC
      data = get_instruction_data(operation, addressing_mode)
      
      data = (data - 1) & 0xFF
      calc_sign_flag(data)
      calc_zero_flag(data)
      @mmc.write_cpu_mem(address, data)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::DEX  #DEX
      @x = (@x - 1) & 0xFF
      calc_sign_flag(@x)
      calc_zero_flag(@x)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::DEY  #DEY
      @y = (@y - 1) & 0xFF
      calc_sign_flag(@y)
      calc_zero_flag(@y)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::EOR  #EOR
      data = get_instruction_data(operation, addressing_mode)

      temp = (data ^ @a)
      calc_zero_flag(temp)
      calc_sign_flag(temp)
      @a = temp
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      cycle_offset = 1 if @page_boundary_crossed
      
      when Operation::INC  #INC
      data = get_instruction_data(operation, addressing_mode)
      
      data = (data + 1) & 0xFF
      calc_sign_flag(data)
      calc_zero_flag(data)
      @mmc.write_cpu_mem(address, data)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::INX  #INX
      @x = (@x + 1) & 0xFF
      calc_sign_flag(@x)
      calc_zero_flag(@x)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::INY  #INY
      @y = (@y + 1) & 0xFF
      calc_sign_flag(@y)
      calc_zero_flag(@y)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::JMP  #JMP
      @pc = address
      
      when Operation::JSR  #JSR
      @pc += 2
      push((@pc >> 8) & 0xFF) # Push high byte first
      push(@pc & 0xFF)
      @pc = address
      
      when Operation::LDA  #LDA
      data = get_instruction_data(operation, addressing_mode)

      calc_sign_flag(data)
      calc_zero_flag(data)
      @a = data
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      cycle_offset = 1 if @page_boundary_crossed
      
      when Operation::LDX  #LDX
      data = get_instruction_data(operation, addressing_mode)

      calc_sign_flag(data)
      calc_zero_flag(data)
      @x = data
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      cycle_offset = 1 if @page_boundary_crossed
      
      when Operation::LDY  #LDY
      data = get_instruction_data(operation, addressing_mode)

      calc_sign_flag(data)
      calc_zero_flag(data)
      @y = data
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      cycle_offset = 1 if @page_boundary_crossed
      
      when Operation::LSR  #LSR
      data = get_instruction_data(operation, addressing_mode)

      set_carry_flag((data & 0x01) != 0)
      data >>= 1
      data &= 0xFF # Reduce to 1-byte data
      calc_zero_flag(data)
      set_sign_flag(false)
      if addressing_mode == ACCUMULATOR
        @a = data
      else
        @mmc.write_cpu_mem(address, data)
      end
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::NOP  #NOP
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::ORA  #ORA
      data = get_instruction_data(operation, addressing_mode)

      temp = (data | @a)
      calc_zero_flag(temp)
      calc_sign_flag(temp)
      @a = temp
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      cycle_offset = 1 if @page_boundary_crossed
      
      when Operation::PHA  #PHA
      push(@a)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::PHP  #PHP
      push(@flags)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::PLA  #PLA
      @a = pop
      # Note: VICE sets these flags, but that functionality isn't in the documentation. What's the right thing to do?
      calc_sign_flag(@a) 
      calc_zero_flag(@a) 
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::PLP  #PLP
      @flags = pop
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::ROL  #ROL
      data = get_instruction_data(operation, addressing_mode)

      carry = (data & 0x80) != 0 ? true : false
      data <<= 1
      data &= 0xFF # Reduce to 1-byte data
      data |= 0x01 if carry_flag_set?
      set_carry_flag(carry)
      
      calc_zero_flag(data)
      calc_sign_flag(data)
      
      if addressing_mode == ACCUMULATOR
        @a = data
      else
        @mmc.write_cpu_mem(address, data)
      end
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::ROR  #ROR
      data = get_instruction_data(operation, addressing_mode)

      carry = (data & 0x01) != 0 ? true : false
      data >>= 1
      data &= 0xFF # Reduce to 1-byte data
      data |= 0x80 if carry_flag_set?
      set_carry_flag(carry)
      
      calc_zero_flag(data)
      calc_sign_flag(data)
      
      if addressing_mode == ACCUMULATOR
        @a = data
      else
        @mmc.write_cpu_mem(address, data)
      end
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::RTI  #RTI
      @flags = pop
      data = (pop & 0xFF)  # Pop low byte first
      data |= (pop << 8)  
      @pc = data
      
      when Operation::RTS  #RTS
      data = (pop & 0xFF)  # Pop low byte first
      data |= (pop << 8)  
      @pc = data + 1
      
      when Operation::SBC  #SBC
      data = get_instruction_data(operation, addressing_mode)

      temp = @a - data - (carry_flag_set? ? 1 : 0)
      calc_zero_flag(temp)
      calc_sign_flag(temp)
      # Note, most of the following logic comes directly from the VICE emulator. 
      #Need to understand it better.
      set_overflow_flag(((@a ^ data) & 0x80) && ((@a ^ temp) & 0x80))  
      
      if (decimal_flag_set?) 
       temp -= 6 if ( ((@a & 0x0F) - (carry_flag_set? ? 0 : 1)) < (data & 0x0F))
       temp -= 0x60 if (temp > 0x99) 
      end

      set_carry_flag(temp < 0x100)
      
      @a = (temp & 0xFF)  # Reduce to 1-byte data
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      cycle_offset = 1 if @page_boundary_crossed
      
      when Operation::SEC  #SEC
      set_carry_flag(true)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::SED  #SED
      set_decimal_flag(true)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::SEI  #SEI
      set_interrupt_flag(true)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::STA  #STA
      @mmc.write_cpu_mem(address, @a)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::STX  #STX
      @mmc.write_cpu_mem(address, @x)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::STY  #STY
      @mmc.write_cpu_mem(address, @y)
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::TAX  #TAX
      calc_sign_flag(@a)
      calc_zero_flag(@a)
      @x = @a
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::TAY  #TAY
      calc_sign_flag(@a)
      calc_zero_flag(@a)
      @y = @a
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::TSX  #TSX
      calc_sign_flag(@sp)
      calc_zero_flag(@sp)
      @x = @sp
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::TXA  #TXA
      calc_sign_flag(@x)
      calc_zero_flag(@x)
      @a = @x
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::TXS  #TXS
      @sp = @x
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
      when Operation::TYA  #TYA
      calc_sign_flag(@y)
      calc_zero_flag(@y)
      @a = @y
      @pc += BYTE_COUNTS[operation][addressing_mode]
      
    end
    
    # Return the number of cycles elapsed
    begin
      return CYCLE_COUNTS[operation][addressing_mode] + cycle_offset
    rescue
      DEBUG.debug_print "Something's Wrong! Invalid operation or addressing mode.\n"
      DEBUG.debug_getcommands
    end
    
  end
  
  
  # Stack Operations
  def push(val)
    if (@sp > 0)
      @mmc.write_cpu_mem(CPU_STACK_LO + @sp, val)
      @sp-=1
    else
      # Error occurred, stack overflow
      DEBUG.debug_print "Stack Overflow Occurred\n"
      DEBUG.debug_getcommands
      raise "Stack Overflow Error"
    end
  end
  
  def pop
    if (@sp < 0xFF)
      @sp+=1
      result = @mmc.read_cpu_mem(CPU_STACK_LO + @sp)
    else
      # Error occurred, stack underflow
      DEBUG.debug_print "Stack Underflow Occurred\n"
      DEBUG.debug_getcommands
      raise "Stack Underflow Error"
    end
    
    return result
  end
  
  private
  # *******
  # ******* Utility Methods
  # *******
  def get_instruction_address(operation, addressing_mode)
    address = 0
    
     # Return address of operand based on addressing mode
    if addressing_mode == IMMEDIATE
      address = get_immediate_address
    elsif addressing_mode == ABSOLUTE
      address = get_absolute_address(false, false)
    elsif addressing_mode == ZERO_PAGE
      address = get_zero_page_address(false, false)
    elsif addressing_mode == ZERO_PAGE_X_INDEXED
      address = get_zero_page_address(true, false)
    elsif addressing_mode == ZERO_PAGE_Y_INDEXED
      address = get_zero_page_address(false, true)
    elsif addressing_mode == ABSOLUTE_X_INDEXED
      address = get_absolute_address(true, false)
    elsif addressing_mode == ABSOLUTE_Y_INDEXED
      address = get_absolute_address(false, true)
    elsif addressing_mode == INDIRECT
      address = get_indirect_address  # Indirect addressing doesn't involve data
    elsif addressing_mode == PRE_INDEXED_INDIRECT
      address = get_preindexed_indirect_address
    elsif addressing_mode == POST_INDEXED_INDIRECT
      address = get_postindexed_indirect_address
    elsif addressing_mode == RELATIVE
      # Note!!! - It's important that we add the bytes here, for the proper calculation
      # of page boundary crossing for relative mode.
      address = get_relative_address(BYTE_COUNTS[operation][addressing_mode])  #Relative addressing doesn't involve data
    end
    
    return address
  end
  
  def get_instruction_data(operation, addressing_mode)
    data = 0
    
     # Return operand data based on addressing mode
    if addressing_mode == IMMEDIATE
      data = get_immediate_value
    elsif addressing_mode == ABSOLUTE
      data = get_absolute_value(false, false)
    elsif addressing_mode == ZERO_PAGE
      data = get_zero_page_value(false, false)
    elsif addressing_mode == ACCUMULATOR
      data = @a
    elsif addressing_mode == ZERO_PAGE_X_INDEXED
      data = get_zero_page_value(true, false)
    elsif addressing_mode == ZERO_PAGE_Y_INDEXED
      data = get_zero_page_value(false, true)
    elsif addressing_mode == ABSOLUTE_X_INDEXED
      data = get_absolute_value(true, false)
    elsif addressing_mode == ABSOLUTE_Y_INDEXED
      data = get_absolute_value(false, true)
    elsif addressing_mode == PRE_INDEXED_INDIRECT
      data = get_preindexed_indirect_value
    elsif addressing_mode == POST_INDEXED_INDIRECT
      data = get_postindexed_indirect_value
    end
    
    return data
  end

  # Status Flag Methods
  # 7 = Sign flag, 6 = Overflow flag, 4 = Break flag, 3 = Decimal mode flag
  # 2 = Interrupt disable flag, 1 = Zero flag, 0 = Carry flag
  def sign_flag_set?
    return (@flags & CPU_STAT_NEGATIVE) != 0 ? true : false
  end
  
  def overflow_flag_set?
    return (@flags & CPU_STAT_OVERFLOW) != 0 ? true : false
  end
  
  def break_flag_set?
    return (@flags & CPU_STAT_BREAK) != 0 ? true : false
  end
  
  def decimal_flag_set?
    return (@flags & CPU_STAT_DECIMAL) != 0 ? true : false
  end
  
  def interrupt_flag_set?
    return (@flags & CPU_STAT_INTERRUPT_DISABLE) != 0 ? true : false
  end
  
  def zero_flag_set?
    return (@flags & CPU_STAT_ZERO) != 0 ? true : false
  end
  
  def carry_flag_set?
    return (@flags & CPU_STAT_CARRY) != 0 ? true : false
  end
  
  # Set boolean value of status flags
  def set_sign_flag(val)
    if (val)
      @flags |= CPU_STAT_NEGATIVE
    else 
      @flags &= ~CPU_STAT_NEGATIVE
    end
  end
  
  def set_overflow_flag(val)
    if (val)
      @flags |= CPU_STAT_OVERFLOW
    else
      @flags &= ~CPU_STAT_OVERFLOW
    end
  end
  
  def set_break_flag(val)
    if (val)
      @flags |= CPU_STAT_BREAK
    else
      @flags &= ~CPU_STAT_BREAK
    end
  end
  
  def set_decimal_flag(val)
    if (val)
      @flags |= CPU_STAT_DECIMAL
    else 
      @flags &= ~CPU_STAT_DECIMAL
    end
  end
  
  def set_interrupt_flag(val)
    if (val)
      @flags |= CPU_STAT_INTERRUPT_DISABLE
    else
      @flags &= ~CPU_STAT_INTERRUPT_DISABLE
    end
  end
  
  def set_zero_flag(val)
    if (val)
      @flags |= CPU_STAT_ZERO
    else
      @flags &= ~CPU_STAT_ZERO
    end
  end
  
  def set_carry_flag(val)
    if (val)
      @flags |= CPU_STAT_CARRY
    else
      @flags &= ~CPU_STAT_CARRY
    end
  end
  
  # Calculate the values of the status flags
  def calc_sign_flag(val)
    if (val & 0x80) != 0
      set_sign_flag(true)
    else 
      set_sign_flag(false)
    end
  end
  
  def calc_zero_flag(val)
    if (val == 0)
      set_zero_flag(true)
    else 
      set_zero_flag(false)
    end
  end
  
  # Methods to get address / data based on addressing mode
  def get_immediate_address
    address = @pc + 1
    return address
  end
  
  def get_immediate_value
    if @debug_read
      result = @mmc.read_cpu_mem_safe(get_immediate_address)
    else
      result = @mmc.read_cpu_mem(get_immediate_address)
    end
    return result
  end
  
  def get_zero_page_address(xindexed,yindexed)
    address = @mmc.read_cpu_mem(@pc + 1)
    
    if (xindexed)
      address += @x
    elsif (yindexed)
      address += @y
    end
    
    return address
  end
  
  def get_zero_page_value(xindexed,yindexed)
    if @debug_read
      result = @mmc.read_cpu_mem_safe(get_zero_page_address(xindexed,yindexed))
    else
      result = @mmc.read_cpu_mem(get_zero_page_address(xindexed,yindexed))
    end
    return result
  end
  
  def get_absolute_address(xindexed,yindexed)
    # Address is stored low byte  first
    address = (@mmc.read_cpu_mem(@pc + 2) << 8) + @mmc.read_cpu_mem(@pc + 1)
    
    if (xindexed)
      @page_boundary_crossed = true if (address & 0xFF00) != ((address + @x) & 0xFF00)
      address += @x
    elsif (yindexed)
      @page_boundary_crossed = true if (address & 0xFF00) != ((address + @y) & 0xFF00)
      address += @y
    end
    
    return address
  end
  
  def get_absolute_value(xindexed,yindexed)
    if @debug_read
      result = @mmc.read_cpu_mem_safe(get_absolute_address(xindexed,yindexed))
    else
      result = @mmc.read_cpu_mem(get_absolute_address(xindexed,yindexed))
    end
    return result
  end
  
  def get_indirect_address
    # Address Location and actual address are stored low byte first
    address_location = (@mmc.read_cpu_mem(@pc + 2) << 8) + @mmc.read_cpu_mem(@pc + 1)
    address = (@mmc.read_cpu_mem(address_location + 1) << 8) + @mmc.read_cpu_mem(address_location)
    return address
  end
  
  def get_preindexed_indirect_address
    # Address location is added to (indexed by) the X register
    address_location = @mmc.read_cpu_mem(@pc + 1) + @x
    # Address is stored low byte first
    address = (@mmc.read_cpu_mem(address_location + 1) << 8) + @mmc.read_cpu_mem(address_location)
    return address
  end
  
  def get_preindexed_indirect_value
    if @debug_read
      result = @mmc.read_cpu_mem_safe(get_preindexed_indirect_address)
    else
      result = @mmc.read_cpu_mem(get_preindexed_indirect_address)
    end
    return result
  end
  
  def get_postindexed_indirect_address
    address_location = @mmc.read_cpu_mem(@pc + 1)
    # Address is stored low byte first, and is added to (indexed by) the Y register
    address = (@mmc.read_cpu_mem(address_location + 1) << 8) + @mmc.read_cpu_mem(address_location)
    
    @page_boundary_crossed = true if (address & 0xFF00) != ((address + @y) & 0xFF00)
    address += @y
    return address
  end
  
  def get_postindexed_indirect_value
    if @debug_read
      result = @mmc.read_cpu_mem_safe(get_postindexed_indirect_address)
    else
      result = @mmc.read_cpu_mem(get_postindexed_indirect_address)
    end
    return result
  end
  
  def get_relative_address(op_offset)
    address_offset = @mmc.read_cpu_mem(@pc + 1)
    
    # Address offset is treated as a signed number
    if ((address_offset & 0x80) == 0)
      @page_boundary_crossed = true if ((@pc + op_offset) & 0xFF00) != ((@pc + address_offset) & 0xFF00)
      address = @pc + address_offset  
    else
      @page_boundary_crossed = true if ((@pc + op_offset) & 0xFF00) != ((@pc + ~(0xFF - address_offset)) & 0xFF00)
      address = @pc + (~(0xFF - address_offset))
    end
    
    return address
  end
  
  
end