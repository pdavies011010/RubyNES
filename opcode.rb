# Constant (enum-ish) definition of opcodes
module Opcode
  # Instruction OpCodes
  # ADC - Add memory to accumulator with carry 
  # * - add 1 cycle if page boundary is crossed
  ADCI=0x69  #ADC Immediate; 2 bytes, 2 cycles
  ADCZ=0x65  #ADC Zero-page absolute; 2 bytes, 3 cycles
  ADCZX=0x75 #ADC Zero-page X-indexed; 2 bytes, 4 cycles
  ADCA=0x6D  #ADC Absolute; 3 bytes, 4 cycles
  ADCAX=0x7D #ADC Absolute X-indexed; 3 bytes, 4 cycles *
  ADCAY=0x79 #ADC Absolute Y-indexed; 3 bytes, 4 cycles *
  ADCIX=0x61 #ADC Indirect Pre-indexed; 2 bytes, 6 cycles
  ADCIY=0x71 #ADC Indirect Post-indexed; 2 bytes, 5 cycles *
  
  # AND - "AND" memory with accumulator
  # * - add 1 cycle if page boundary is crossed
  ANDI=0x29  #AND Immediate; 2 bytes, 2 cycles
  ANDZ=0x25  #AND Zero-page absolute; 2 bytes, 3 cycles
  ANDZX=0x35 #AND Zero-page X-indexed; 2 bytes, 4 cycles
  ANDA=0x2D  #AND Absolute; 3 bytes, 4 cycles
  ANDAX=0x3D #AND Absolute X-indexed; 3 bytes, 4 cycles *
  ANDAY=0x39 #AND Absolute Y-indexed; 3 bytes, 4 cycles *
  ANDIX=0x21 #AND Indirect Pre-indexed; 2 bytes, 6 cycles
  ANDIY=0x31 #AND Indirect Post-indexed; 2 bytes, 5 cycles *
  
  # ASL - ASL Shift Left One Bit (Memory or Accumulator)
  ASL=0x0A   #ASL Accumulator; 1 byte, 2 cycles
  ASLZ=0x06  #ASL Zero-page absolute; 2 bytes, 5 cycles
  ASLZX=0x16 #ASL Zero-page X-indexed; 2 bytes, 6 cycles
  ASLA=0x0E  #ASL Absolute; 3 bytes, 6 cycles
  ASLAX=0x1E #ASL Absolute X-indexed; 3 bytes, 7 cycles
  
  # BCC - BCC Branch on Carry Clear
  # * - add 1 cycle if page boundary is not crossed, 2 if it is
  BCC=0x90   #BCC (Relative); 2 bytes, 2 cycles *
  
  # BCS - BCS Branch on carry set
  # * - add 1 cycle if page boundary is not crossed, 2 if it is
  BCS=0xB0   #BCC (Relative); 2 bytes, 2 cycles *
  
  # BEQ - BEQ Branch on result zero
  # * - add 1 cycle if page boundary is not crossed, 2 if it is
  BEQ=0xF0   #BCC (Relative); 2 bytes, 2 cycles *
  
  # BIT - BIT Test bits in memory with accumulator
  BITZ=0x24  #BIT Zero-page absolute; 2 bytes, 3 cycles
  BITA=0x2C  #BIT Absolute; 3 bytes, 4 cycles
  
  # BMI - BMI Branch on result minus
  # * - add 1 cycle if page boundary is not crossed, 2 if it is
  BMI=0x30   #BMI (Relative); 2 bytes, 2 cycles *
  
  # BNE - BNE Branch on result not zero
  # * - add 1 cycle if page boundary is not crossed, 2 if it is
  BNE=0xD0   #BNE (Relative); 2 bytes, 2 cycles *
  
  # BPL - BPL Branch on result plus
  # * - add 1 cycle if page boundary is not crossed, 2 if it is
  BPL=0x10   #BPL (Relative); 2 bytes, 2 cycles *
  
  # BRK - BRK Force Break
  BRK=0x00   #BRK (Implied); 1 byte, 7 cycles
  
  # BVC - BVC Branch on overflow clear
  # * - add 1 cycle if page boundary is not crossed, 2 if it is
  BVC=0x50   #BVC (Relative); 2 bytes, 2 cycles *
  
  # BVS - BVS Branch on overflow set
  # * - add 1 cycle if page boundary is not crossed, 2 if it is
  BVS=0x70   #BVS (Relative); 2 bytes, 2 cycles *
  
  # CLC - CLC Clear carry flag
  CLC=0x18   #CLC (Implied); 1 byte, 2 cycles
  
  # CLD - CLD Clear decimal mode flag 
  CLD=0xD8   #CLD (Implied); 1 byte, 2 cycles
  
  # CLI - CLI Clear interrupt disable flag
  CLI=0x58   #CLI (Implied); 1 byte, 2 cycles
  
  # CLV - CLV Clear overflow flag
  CLV=0xB8   #CLV (Implied); 1 byte, 2 cycles
  
  # CMP - CMP Compare memory and accumulator
  # * - add 1 cycle if page boundary is crossed
  CMPI=0xC9  #CMP Immediate; 2 bytes, 2 cycles
  CMPZ=0xC5  #CMP Zero-page absolute; 2 bytes, 3 cycles
  CMPZX=0xD5 #CMP Zero-page X-indexed; 2 bytes, 4 cycles
  CMPA=0xCD  #CMP Absolute; 3 bytes, 4 cycles
  CMPAX=0xDD #CMP Absolute X-indexed; 3 bytes, 4 cycles *
  CMPAY=0xD9 #CMP Absolute Y-indexed; 3 bytes, 4 cycles *
  CMPIX=0xC1 #CMP Indirect Pre-indexed; 2 bytes, 6 cycles
  CMPIY=0xD1 #CMP Indirect Post-indexed; 2 bytes, 5 cycles *
  
  # CPX - CPX Compare Memory and Index X
  CPXI=0xE0  #CPX Immediate; 2 bytes, 2 cycles
  CPXZ=0xE4  #CPX Zero-page absolute; 2 bytes, 3 cycles
  CPXA=0xEC  #CPX Absolute; 3 bytes, 4 cycles
  
  # CPY - CPY Compare Memory and Index Y
  CPYI=0xC0  #CPY Immediate; 2 bytes, 2 cycles
  CPYZ=0xC4  #CPY Zero-page absolute; 2 bytes, 3 cycles
  CPYA=0xCC  #CPY Absolute; 3 bytes, 4 cycles
  
  # DEC - DEC Decrement memory by one
  DECZ=0xC6  #DEC Zero-page absolute; 2 bytes, 5 cycles
  DECZX=0xD6 #DEC Zero-page X-indexed; 2 bytes, 6 cycles
  DECA=0xCE  #DEC Absolute; 3 bytes, 6 cycles
  DECAX=0xDE #DEC Absolute X-indexed; 3 bytes, 7 cycles
  
  # DEX - DEX Decrement index X by one
  DEX=0xCA   #DEX (Implied); 1 byte, 2 cycles
  
  # DEY - DEY Decrement index Y by one
  DEY=0x88   #DEY (Implied); 1 byte, 2 cycles
  
  # EOR - EOR "Exclusive-Or" memory with accumulator
  # * - add 1 cycle if page boundary is crossed
  EORI=0x49  #EOR Immediate; 2 bytes, 2 cycles
  EORZ=0x45  #EOR Zero-page absolute; 2 bytes, 3 cycles
  EORZX=0x55 #EOR Zero-page X-indexed; 2 bytes, 4 cycles
  EORA=0x4D  #EOR Absolute; 3 bytes, 4 cycles
  EORAX=0x5D #EOR Absolute X-indexed; 3 bytes, 4 cycles *
  EORAY=0x59 #EOR Absolute Y-indexed; 3 bytes, 4 cycles *
  EORIX=0x41 #EOR Indirect Pre-indexed; 2 bytes, 6 cycles
  EORIY=0x51 #EOR Indirect Post-indexed; 2 bytes, 5 cycles *
  
  # INC - INC Increment memory by one
  INCZ=0xE6  #INC Zero-page absolute; 2 bytes, 5 cycles
  INCZX=0xF6 #INC Zero-page X-indexed; 2 bytes, 6 cycles
  INCA=0xEE  #INC Absolute; 3 bytes, 6 cycles
  INCAX=0xFE #INC Absolute X-indexed; 3 bytes, 7 cycles
  
  # INX - INX Increment Index X by one
  INX=0xE8   #INX (Implied); 1 byte, 2 cycles  
  
  # INY - INY Increment Index Y by one
  INY=0xC8   #INY (Implied); 1 byte, 2 cycles 
  
  # JMP - JMP Jump to new location
  JMPA=0x4C  #JMP Absolute; 3 bytes, 3 cycles
  JMPI=0x6C  #JMP Indirect; 3 bytes, 5 cycles
  
  # JSR - JSR Jump to new location saving return address
  JSRA=0x20  #JSR Absolute; 3 bytes, 6 cycles
  
  # LDA - LDA Load accumulator with memory
  # * - add 1 cycle if page boundary is crossed
  LDAI=0xA9  #LDA Immediate; 2 bytes, 2 cycles
  LDAZ=0xA5  #LDA Zero-page absolute; 2 bytes, 3 cycles
  LDAZX=0xB5 #LDA Zero-page X-indexed; 2 bytes, 4 cycles
  LDAA=0xAD  #LDA Absolute; 3 bytes, 4 cycles
  LDAAX=0xBD #LDA Absolute X-indexed; 3 bytes, 4 cycles *
  LDAAY=0xB9 #LDA Absolute Y-indexed; 3 bytes, 4 cycles *
  LDAIX=0xA1 #LDA Indirect Pre-indexed; 2 bytes, 6 cycles
  LDAIY=0xB1 #LDA Indirect Post-indexed; 2 bytes, 5 cycles *
  
  # LDX - LDX Load index X with memory
  # * - add 1 cycle if page boundary is crossed
  LDXI=0xA2  #LDX Immediate; 2 bytes, 2 cycles
  LDXZ=0xA6  #LDX Zero-page absolute; 2 bytes, 3 cycles
  LDXZY=0xB6 #LDX Zero-page Y-indexed; 2 bytes, 4 cycles
  LDXA=0xAE  #LDX Absolute; 3 bytes, 4 cycles
  LDXAY=0xBE #LDX Absolute Y-indexed; 3 bytes, 4 cycles *
  
  # LDY - LDY Load index Y with memory
  # * - add 1 cycle if page boundary is crossed
  LDYI=0xA0  #LDY Immediate; 2 bytes, 2 cycles
  LDYZ=0xA4  #LDY Zero-page absolute; 2 bytes, 3 cycles
  LDYZX=0xB4 #LDY Zero-page X-indexed; 2 bytes, 4 cycles
  LDYA=0xAC  #LDY Absolute; 3 bytes, 4 cycles
  LDYAX=0xBC #LDY Absolute X-indexed; 3 bytes, 4 cycles *
  
  # LSR - LSR Shift right one bit (memory or accumulator)
  LSR=0x4A   #LSR Accumulator; 1 byte, 2 cycles
  LSRZ=0x46  #LSR Zero-page absolute; 2 bytes, 5 cycles
  LSRZX=0x56 #LSR Zero-page X-indexed; 2 bytes, 6 cycles
  LSRA=0x4E  #LSR Absolute; 3 bytes, 6 cycles
  LSRAX=0x5E #LSR Absolute X-indexed; 3 bytes, 7 cycles
  
  # NOP - NOP No operation 
  NOP=0xEA   #NOP Implied; 1 byte, 2 cycles
  
  # ORA - ORA "OR" memory with accumulator
  # * - add 1 cycle if page boundary is crossed
  ORAI=0x09  #ORA Immediate; 2 bytes, 2 cycles
  ORAZ=0x05  #ORA Zero-page absolute; 2 bytes, 3 cycles
  ORAZX=0x15 #ORA Zero-page X-indexed; 2 bytes, 4 cycles
  ORAA=0x0D  #ORA Absolute; 3 bytes, 4 cycles
  ORAAX=0x1D #ORA Absolute X-indexed; 3 bytes, 4 cycles *
  ORAAY=0x19 #ORA Absolute Y-indexed; 3 bytes, 4 cycles *
  ORAIX=0x01 #ORA Indirect Pre-indexed; 2 bytes, 6 cycles
  ORAIY=0x11 #ORA Indirect Post-indexed; 2 bytes, 5 cycles
  
  # PHA - PHA Push accumulator on stack 
  PHA=0x48   #PHA (Implied); 1 byte, 3 cycles
  
  # PHP - PHP Push processor status on stack 
  PHP=0x08   #PHP (Implied); 1 byte, 3 cycles
  
  # PLA - PLA Pull accumulator from stack 
  PLA=0x68   #PLA (Implied); 1 byte, 4 cycles
  
  # PLP - PLP Pull processor status from stack
  PLP=0x28   #PLP (Implied); 1 byte, 4 cycles
  
  # ROL - ROL Rotate one bit left (memory or accumulator)
  ROL=0x2A   #ROL Accumulator; 1 bytes, 2 cycles
  ROLZ=0x26  #ROL Zero-page absolute; 2 bytes, 5 cycles
  ROLZX=0x36 #ROL Zero-page X-indexed; 2 bytes, 6 cycles
  ROLA=0x2E  #ROL Absolute; 3 bytes, 6 cycles
  ROLAX=0x3E #ROL Absolute X-indexed; 3 bytes, 7 cycles 
  
  # ROR - ROR Rotate one bit right (memory or accumulator)
  ROR=0x6A   #ROR Accumulator; 1 bytes, 2 cycles
  RORZ=0x66  #ROR Zero-page absolute; 2 bytes, 5 cycles
  RORZX=0x76 #ROR Zero-page X-indexed; 2 bytes, 6 cycles
  RORA=0x6E  #ROR Absolute; 3 bytes, 6 cycles
  RORAX=0x7E #ROR Absolute X-indexed; 3 bytes, 7 cycles 
  
  # RTI - RTI Return from interrupt
  RTI=0x40   #RTI (Implied); 1 byte, 6 cycles
  
  # RTS - RTS Return from subroutine
  RTS=0x60   #RTS (Implied); 1 byte, 6 cycles
  
  # SBC - SBC Subtract memory from accumulator with borrow
  # * - add 1 cycle if page boundary is crossed
  SBCI=0xE9  #SBC Immediate; 2 bytes, 2 cycles
  SBCZ=0xE5  #SBC Zero-page absolute; 2 bytes, 3 cycles
  SBCZX=0xF5 #SBC Zero-page X-indexed; 2 bytes, 4 cycles
  SBCA=0xED  #SBC Absolute; 3 bytes, 4 cycles
  SBCAX=0xFD #SBC Absolute X-indexed; 3 bytes, 4 cycles *
  SBCAY=0xF9 #SBC Absolute Y-indexed; 3 bytes, 4 cycles *
  SBCIX=0xE1 #SBC Indirect Pre-indexed; 2 bytes, 6 cycles
  SBCIY=0xF1 #SBC Indirect Post-indexed; 2 bytes, 5 cycles
  
  # SEC - SEC Set carry flag
  SEC=0x38   #SEC (Implied); 1 byte, 2 cycles
  
  # SED - SED Set decimal mode flag
  SED=0xF8   #SED (Implied); 1 byte, 2 cycles
  
  # SEI - SEI Set interrupt disable status flag
  SEI=0x78   #SEI (Implied); 1 byte, 2 cycles
  
  # STA - STA Store accumulator in memory
  STAZ=0x85  #STA Zero-page absolute; 2 bytes, 3 cycles
  STAZX=0x95 #STA Zero-page X-indexed; 2 bytes, 4 cycles
  STAA=0x8D  #STA Absolute; 3 bytes, 4 cycles
  STAAX=0x9D #STA Absolute X-indexed; 3 bytes, 5 cycles
  STAAY=0x99 #STA Absolute Y-indexed; 3 bytes, 5 cycles
  STAIX=0x81 #STA Indirect Pre-indexed; 2 bytes, 6 cycles
  STAIY=0x91 #STA Indirect Post-indexed; 2 bytes, 6 cycles
  
  # STX - STX Store index X in memory 
  STXZ=0x86  #STX Zero-page absolute; 2 bytes, 3 cycles
  STXZX=0x96 #STX Zero-page Y-indexed; 2 bytes, 4 cycles
  STXA=0x8E  #STX Absolute; 3 bytes, 4 cycles
  
  # STY - STY Store index Y in memory 
  STYZ=0x84  #STY Zero-page absolute; 2 bytes, 3 cycles
  STYZX=0x94 #STY Zero-page X-indexed; 2 bytes, 4 cycles
  STYA=0x8C  #STY Absolute; 3 bytes, 4 cycles
  
  # TAX - TAX Transfer accumulator to index X
  TAX=0xAA   #TAX (Implied); 1 byte, 2 cycles  
  
  # TAY - TAY Transfer accumulator to index Y
  TAY=0xA8   #TAY (Implied); 1 byte, 2 cycles
  
  # TSX - TSX Transfer stack pointer to index X
  TSX=0xBA   #TSX (Implied); 1 byte, 2 cycles
  
  # TXA - TXA Transfer index X to accumulator
  TXA=0x8A   #TXA (Implied); 1 byte, 2 cycles
  
  # TXS - TXS Transfer index X to stack pointer
  TXS=0x9A   #TXS (Implied); 1 byte, 2 cycles
  
  # TYA - TYA Transfer index Y to accumulator
  TYA=0x98   #TYA (Implied); 1 byte, 2 cycles
end