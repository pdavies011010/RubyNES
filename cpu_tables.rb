require "opcode"
require "operation"
require "addressing_mode"

module CpuTables
  include Opcode
  include AddressingMode
  
  # Operation Hash (OPERATIONS[opcode] -> operation)
  OPERATIONS = {ADCI => Operation::ADC, ADCZ => Operation::ADC, ADCZX => Operation::ADC, ADCA => Operation::ADC, ADCAX => Operation::ADC, ADCAY => Operation::ADC, ADCIX => Operation::ADC, ADCIY => Operation::ADC,
  ANDI => Operation::AND, ANDZ => Operation::AND, ANDZX => Operation::AND, ANDA => Operation::AND, ANDAX => Operation::AND, ANDAY => Operation::AND, ANDIX => Operation::AND, ANDIY => Operation::AND,
  ASL => Operation::ASL, ASLZ => Operation::ASL, ASLZX => Operation::ASL, ASLA => Operation::ASL, ASLAX => Operation::ASL,
  BCC => Operation::BCC,
  BCS => Operation::BCS,
  BEQ => Operation::BEQ,
  BITZ => Operation::BIT, BITA => Operation::BIT,
  BMI => Operation::BMI,
  BNE => Operation::BNE,
  BPL => Operation::BPL,
  BRK => Operation::BRK,
  BVC => Operation::BVC,
  BVS => Operation::BVS,
  CLC => Operation::CLC,
  CLD => Operation::CLD,
  CLI => Operation::CLI,
  CLV => Operation::CLV,
  CMPI => Operation::CMP, CMPZ => Operation::CMP, CMPZX => Operation::CMP, CMPA => Operation::CMP, CMPAX => Operation::CMP, CMPAY => Operation::CMP, CMPIX => Operation::CMP, CMPIY => Operation::CMP,
  CPXI => Operation::CPX, CPXZ => Operation::CPX, CPXA => Operation::CPX,
  CPYI => Operation::CPY, CPYZ => Operation::CPY, CPYA => Operation::CPY,
  DECZ => Operation::DEC, DECZX => Operation::DEC, DECA => Operation::DEC, DECAX => Operation::DEC,
  DEX => Operation::DEX,
  DEY => Operation::DEY,
  EORI => Operation::EOR, EORZ => Operation::EOR, EORZX => Operation::EOR, EORA => Operation::EOR, EORAX => Operation::EOR, EORAY => Operation::EOR, EORIX => Operation::EOR, EORIY => Operation::EOR,
  INCZ => Operation::INC, INCZX => Operation::INC, INCA => Operation::INC, INCAX => Operation::INC,
  INX => Operation::INX,
  INY => Operation::INY,
  JMPA => Operation::JMP, JMPI => Operation::JMP,
  JSRA => Operation::JSR,
  LDAI => Operation::LDA, LDAZ => Operation::LDA, LDAZX => Operation::LDA, LDAA => Operation::LDA, LDAAX => Operation::LDA, LDAAY => Operation::LDA, LDAIX => Operation::LDA, LDAIY => Operation::LDA,
  LDXI => Operation::LDX, LDXZ => Operation::LDX, LDXZY => Operation::LDX, LDXA => Operation::LDX, LDXAY => Operation::LDX,
  LDYI => Operation::LDY, LDYZ => Operation::LDY, LDYZX => Operation::LDY, LDYA => Operation::LDY, LDYAX => Operation::LDY,
  LSR => Operation::LSR, LSRZ => Operation::LSR, LSRZX => Operation::LSR, LSRA => Operation::LSR, LSRAX => Operation::LSR,
  NOP => Operation::NOP,
  ORAI => Operation::ORA, ORAZ => Operation::ORA, ORAZX => Operation::ORA, ORAA => Operation::ORA, ORAAX => Operation::ORA, ORAAY => Operation::ORA, ORAIX => Operation::ORA, ORAIY => Operation::ORA,
  PHA => Operation::PHA,
  PHP => Operation::PHP,
  PLA => Operation::PLA,
  PLP => Operation::PLP,
  ROL => Operation::ROL, ROLZ => Operation::ROL, ROLZX => Operation::ROL, ROLA => Operation::ROL, ROLAX => Operation::ROL,
  ROR => Operation::ROR, RORZ => Operation::ROR, RORZX => Operation::ROR, RORA => Operation::ROR, RORAX => Operation::ROR,
  RTI => Operation::RTI,
  RTS => Operation::RTS,
  SBCI => Operation::SBC, SBCZ => Operation::SBC, SBCZX => Operation::SBC, SBCA => Operation::SBC, SBCAX => Operation::SBC, SBCAY => Operation::SBC, SBCIX => Operation::SBC, SBCIY => Operation::SBC,
  SEC => Operation::SEC,
  SED => Operation::SED,
  SEI => Operation::SEI,
  STAZ => Operation::STA, STAZX => Operation::STA, STAA => Operation::STA, STAAX => Operation::STA, STAAY => Operation::STA, STAIX => Operation::STA, STAIY => Operation::STA,
  STXZ => Operation::STX, STXZX => Operation::STX, STXA => Operation::STX,
  STYZ => Operation::STY, STYZX => Operation::STY, STYA => Operation::STY,
  TAX => Operation::TAX,
  TAY => Operation::TAY,
  TSX => Operation::TSX,
  TXA => Operation::TXA,
  TXS => Operation::TXS,
  TYA => Operation::TYA}
  
  # Addressing Mode hash (ADDRESSING_MODES[opcode] -> addressing_mode)
  ADDRESSING_MODES = {ADCI => AddressingMode::IMMEDIATE, ANDI => AddressingMode::IMMEDIATE, CMPI => AddressingMode::IMMEDIATE, CPXI => AddressingMode::IMMEDIATE, CPYI => AddressingMode::IMMEDIATE, EORI => AddressingMode::IMMEDIATE, LDAI => AddressingMode::IMMEDIATE, LDXI => AddressingMode::IMMEDIATE, LDYI => AddressingMode::IMMEDIATE, ORAI => AddressingMode::IMMEDIATE, SBCI => AddressingMode::IMMEDIATE,
  ADCA => AddressingMode::ABSOLUTE, ANDA => AddressingMode::ABSOLUTE, ASLA => AddressingMode::ABSOLUTE, BITA => AddressingMode::ABSOLUTE, CMPA => AddressingMode::ABSOLUTE, CPXA => AddressingMode::ABSOLUTE, CPYA => AddressingMode::ABSOLUTE, DECA => AddressingMode::ABSOLUTE, EORA => AddressingMode::ABSOLUTE, INCA => AddressingMode::ABSOLUTE, JMPA => AddressingMode::ABSOLUTE, JSRA => AddressingMode::ABSOLUTE,
    LDAA => AddressingMode::ABSOLUTE, LDXA => AddressingMode::ABSOLUTE, LDYA => AddressingMode::ABSOLUTE, LSRA => AddressingMode::ABSOLUTE, ORAA => AddressingMode::ABSOLUTE, ROLA => AddressingMode::ABSOLUTE, RORA => AddressingMode::ABSOLUTE, SBCA => AddressingMode::ABSOLUTE, STAA => AddressingMode::ABSOLUTE, STXA => AddressingMode::ABSOLUTE, STYA => AddressingMode::ABSOLUTE,
  ADCZ => AddressingMode::ZERO_PAGE, ANDZ => AddressingMode::ZERO_PAGE, ASLZ => AddressingMode::ZERO_PAGE, BITZ => AddressingMode::ZERO_PAGE, CMPZ => AddressingMode::ZERO_PAGE, CPXZ => AddressingMode::ZERO_PAGE, CPYZ => AddressingMode::ZERO_PAGE, DECZ => AddressingMode::ZERO_PAGE, EORZ => AddressingMode::ZERO_PAGE, INCZ => AddressingMode::ZERO_PAGE, LDAZ => AddressingMode::ZERO_PAGE, LDXZ => AddressingMode::ZERO_PAGE,
    LDYZ => AddressingMode::ZERO_PAGE, LSRZ => AddressingMode::ZERO_PAGE, ORAZ => AddressingMode::ZERO_PAGE, ROLZ => AddressingMode::ZERO_PAGE, RORZ => AddressingMode::ZERO_PAGE, SBCZ => AddressingMode::ZERO_PAGE, STAZ => AddressingMode::ZERO_PAGE, STXZ => AddressingMode::ZERO_PAGE, STYZ => AddressingMode::ZERO_PAGE,
  BRK => AddressingMode::IMPLIED, CLC => AddressingMode::IMPLIED, CLD => AddressingMode::IMPLIED, CLI => AddressingMode::IMPLIED, CLV => AddressingMode::IMPLIED, DEX => AddressingMode::IMPLIED, DEY => AddressingMode::IMPLIED, INX => AddressingMode::IMPLIED, INY => AddressingMode::IMPLIED, NOP => AddressingMode::IMPLIED, PHA => AddressingMode::IMPLIED, PHP => AddressingMode::IMPLIED, PLA => AddressingMode::IMPLIED, PLP => AddressingMode::IMPLIED, 
    RTI => AddressingMode::IMPLIED, RTS => AddressingMode::IMPLIED, SEC => AddressingMode::IMPLIED, SED => AddressingMode::IMPLIED, SEI => AddressingMode::IMPLIED, TAX => AddressingMode::IMPLIED, TAY => AddressingMode::IMPLIED, TSX => AddressingMode::IMPLIED, TXA => AddressingMode::IMPLIED, TXS => AddressingMode::IMPLIED, TYA => AddressingMode::IMPLIED,
  ASL => AddressingMode::ACCUMULATOR, LSR => AddressingMode::ACCUMULATOR, ROL => AddressingMode::ACCUMULATOR, ROR => AddressingMode::ACCUMULATOR,
  ADCZX => AddressingMode::ZERO_PAGE_X_INDEXED, ANDZX => AddressingMode::ZERO_PAGE_X_INDEXED, ASLZX => AddressingMode::ZERO_PAGE_X_INDEXED, CMPZX => AddressingMode::ZERO_PAGE_X_INDEXED, DECZX => AddressingMode::ZERO_PAGE_X_INDEXED, EORZX => AddressingMode::ZERO_PAGE_X_INDEXED, INCZX => AddressingMode::ZERO_PAGE_X_INDEXED, LDAZX => AddressingMode::ZERO_PAGE_X_INDEXED, LDYZX => AddressingMode::ZERO_PAGE_X_INDEXED, LSRZX => AddressingMode::ZERO_PAGE_X_INDEXED, 
    ORAZX => AddressingMode::ZERO_PAGE_X_INDEXED, ROLZX => AddressingMode::ZERO_PAGE_X_INDEXED, RORZX => AddressingMode::ZERO_PAGE_X_INDEXED, SBCZX => AddressingMode::ZERO_PAGE_X_INDEXED, STAZX => AddressingMode::ZERO_PAGE_X_INDEXED, STYZX => AddressingMode::ZERO_PAGE_X_INDEXED,
  LDXZY => AddressingMode::ZERO_PAGE_Y_INDEXED, STXZX => AddressingMode::ZERO_PAGE_Y_INDEXED,
  ADCAX => AddressingMode::ABSOLUTE_X_INDEXED, ANDAX => AddressingMode::ABSOLUTE_X_INDEXED, ASLAX => AddressingMode::ABSOLUTE_X_INDEXED, CMPAX => AddressingMode::ABSOLUTE_X_INDEXED, DECAX => AddressingMode::ABSOLUTE_X_INDEXED, EORAX => AddressingMode::ABSOLUTE_X_INDEXED, INCAX => AddressingMode::ABSOLUTE_X_INDEXED, LDAAX => AddressingMode::ABSOLUTE_X_INDEXED, LDYAX => AddressingMode::ABSOLUTE_X_INDEXED, LSRAX => AddressingMode::ABSOLUTE_X_INDEXED,
    ORAAX => AddressingMode::ABSOLUTE_X_INDEXED, ROLAX => AddressingMode::ABSOLUTE_X_INDEXED, RORAX => AddressingMode::ABSOLUTE_X_INDEXED, SBCAX => AddressingMode::ABSOLUTE_X_INDEXED, STAAX => AddressingMode::ABSOLUTE_X_INDEXED,
  ADCAY => AddressingMode::ABSOLUTE_Y_INDEXED, ANDAY => AddressingMode::ABSOLUTE_Y_INDEXED, CMPAY => AddressingMode::ABSOLUTE_Y_INDEXED, EORAY => AddressingMode::ABSOLUTE_Y_INDEXED, LDAAY => AddressingMode::ABSOLUTE_Y_INDEXED, LDXAY => AddressingMode::ABSOLUTE_Y_INDEXED, ORAAY => AddressingMode::ABSOLUTE_Y_INDEXED, SBCAY => AddressingMode::ABSOLUTE_Y_INDEXED, STAAY => AddressingMode::ABSOLUTE_Y_INDEXED,
  JMPI => AddressingMode::INDIRECT,
  ADCIX => AddressingMode::PRE_INDEXED_INDIRECT, ANDIX => AddressingMode::PRE_INDEXED_INDIRECT, CMPIX => AddressingMode::PRE_INDEXED_INDIRECT, EORIX => AddressingMode::PRE_INDEXED_INDIRECT, LDAIX => AddressingMode::PRE_INDEXED_INDIRECT, ORAIX => AddressingMode::PRE_INDEXED_INDIRECT, SBCIX => AddressingMode::PRE_INDEXED_INDIRECT, STAIX => AddressingMode::PRE_INDEXED_INDIRECT,
  ADCIY => AddressingMode::POST_INDEXED_INDIRECT, ANDIY => AddressingMode::POST_INDEXED_INDIRECT, CMPIY => AddressingMode::POST_INDEXED_INDIRECT, EORIY => AddressingMode::POST_INDEXED_INDIRECT, LDAIY => AddressingMode::POST_INDEXED_INDIRECT, ORAIY => AddressingMode::POST_INDEXED_INDIRECT, SBCIY => AddressingMode::POST_INDEXED_INDIRECT, STAIY => AddressingMode::POST_INDEXED_INDIRECT,
  BCC => AddressingMode::RELATIVE, BCS => AddressingMode::RELATIVE, BEQ => AddressingMode::RELATIVE, BMI => AddressingMode::RELATIVE, BNE => AddressingMode::RELATIVE, BPL => AddressingMode::RELATIVE, BVC => AddressingMode::RELATIVE, BVS => AddressingMode::RELATIVE}
  
  
  
  # Cycle Count hashes (CYCLE_COUNTS[operation][addressing_mode] -> cycle_count)
  CYCLE_COUNTS = Array.new
  CYCLE_COUNTS[Operation::ADC] = {IMMEDIATE => 2, ZERO_PAGE => 3, ZERO_PAGE_X_INDEXED => 4, ABSOLUTE => 4, ABSOLUTE_X_INDEXED => 4, ABSOLUTE_Y_INDEXED => 4, PRE_INDEXED_INDIRECT => 6, POST_INDEXED_INDIRECT => 5}  
  CYCLE_COUNTS[Operation::AND] = {IMMEDIATE => 2, ZERO_PAGE => 3, ZERO_PAGE_X_INDEXED => 4, ABSOLUTE => 4, ABSOLUTE_X_INDEXED => 4, ABSOLUTE_Y_INDEXED => 4, PRE_INDEXED_INDIRECT => 6, POST_INDEXED_INDIRECT => 5}
  CYCLE_COUNTS[Operation::ASL] = {ACCUMULATOR => 2, ZERO_PAGE => 5, ZERO_PAGE_X_INDEXED => 6, ABSOLUTE => 6, ABSOLUTE_X_INDEXED => 7}
  CYCLE_COUNTS[Operation::BCC] = {RELATIVE => 2}
  CYCLE_COUNTS[Operation::BCS] = {RELATIVE => 2}
  CYCLE_COUNTS[Operation::BEQ] = {RELATIVE => 2}
  CYCLE_COUNTS[Operation::BIT] = {ZERO_PAGE => 3, ABSOLUTE => 4}
  CYCLE_COUNTS[Operation::BMI] = {RELATIVE => 2}
  CYCLE_COUNTS[Operation::BNE] = {RELATIVE => 2}
  CYCLE_COUNTS[Operation::BPL] = {RELATIVE => 2}
  CYCLE_COUNTS[Operation::BRK] = {IMPLIED => 7}
  CYCLE_COUNTS[Operation::BVC] = {RELATIVE => 2}
  CYCLE_COUNTS[Operation::BVS] = {RELATIVE => 2}
  CYCLE_COUNTS[Operation::CLC] = {IMPLIED => 2}
  CYCLE_COUNTS[Operation::CLD] = {IMPLIED => 2}
  CYCLE_COUNTS[Operation::CLI] = {IMPLIED => 2}
  CYCLE_COUNTS[Operation::CLV] = {IMPLIED => 2}  
  CYCLE_COUNTS[Operation::CMP] = {IMMEDIATE => 2, ZERO_PAGE => 3, ZERO_PAGE_X_INDEXED => 4, ABSOLUTE => 4, ABSOLUTE_X_INDEXED => 4, ABSOLUTE_Y_INDEXED => 4, PRE_INDEXED_INDIRECT => 6, POST_INDEXED_INDIRECT => 5}  
  CYCLE_COUNTS[Operation::CPX] = {IMMEDIATE => 2, ZERO_PAGE => 3, ABSOLUTE => 4}  
  CYCLE_COUNTS[Operation::CPY] = {IMMEDIATE => 2, ZERO_PAGE => 3, ABSOLUTE => 4}
  CYCLE_COUNTS[Operation::DEC] = {ZERO_PAGE => 5, ZERO_PAGE_X_INDEXED => 6, ABSOLUTE => 6, ABSOLUTE_X_INDEXED => 7}
  CYCLE_COUNTS[Operation::DEX] = {IMPLIED => 2}
  CYCLE_COUNTS[Operation::DEY] = {IMPLIED => 2} 
  CYCLE_COUNTS[Operation::EOR] = {IMMEDIATE => 2, ZERO_PAGE => 3, ZERO_PAGE_X_INDEXED => 4, ABSOLUTE => 4, ABSOLUTE_X_INDEXED => 4, ABSOLUTE_Y_INDEXED => 4, PRE_INDEXED_INDIRECT => 6, POST_INDEXED_INDIRECT => 5}
  CYCLE_COUNTS[Operation::INC] = {ZERO_PAGE => 5, ZERO_PAGE_X_INDEXED => 6, ABSOLUTE => 6, ABSOLUTE_X_INDEXED => 7}
  CYCLE_COUNTS[Operation::INX] = {IMPLIED => 2}
  CYCLE_COUNTS[Operation::INY] = {IMPLIED => 2} 
  CYCLE_COUNTS[Operation::JMP] = {ABSOLUTE => 3, INDIRECT => 5}
  CYCLE_COUNTS[Operation::JSR] = {ABSOLUTE => 6}
  CYCLE_COUNTS[Operation::LDA] = {IMMEDIATE => 2, ZERO_PAGE => 3, ZERO_PAGE_X_INDEXED => 4, ABSOLUTE => 4, ABSOLUTE_X_INDEXED => 4, ABSOLUTE_Y_INDEXED => 4, PRE_INDEXED_INDIRECT => 6, POST_INDEXED_INDIRECT => 5}
  CYCLE_COUNTS[Operation::LDX] = {IMMEDIATE => 2, ZERO_PAGE => 3, ZERO_PAGE_Y_INDEXED => 4, ABSOLUTE => 4, ABSOLUTE_Y_INDEXED => 4}
  CYCLE_COUNTS[Operation::LDY] = {IMMEDIATE => 2, ZERO_PAGE => 3, ZERO_PAGE_X_INDEXED => 4, ABSOLUTE => 4, ABSOLUTE_X_INDEXED => 4}
  CYCLE_COUNTS[Operation::LSR] = {ACCUMULATOR => 2, ZERO_PAGE => 5, ZERO_PAGE_X_INDEXED => 6, ABSOLUTE => 6, ABSOLUTE_X_INDEXED => 7}
  CYCLE_COUNTS[Operation::NOP] = {IMPLIED => 2} 
  CYCLE_COUNTS[Operation::ORA] = {IMMEDIATE => 2, ZERO_PAGE => 3, ZERO_PAGE_X_INDEXED => 4, ABSOLUTE => 4, ABSOLUTE_X_INDEXED => 4, ABSOLUTE_Y_INDEXED => 4, PRE_INDEXED_INDIRECT => 6, POST_INDEXED_INDIRECT => 5}
  CYCLE_COUNTS[Operation::PHA] = {IMPLIED => 3} 
  CYCLE_COUNTS[Operation::PHP] = {IMPLIED => 3} 
  CYCLE_COUNTS[Operation::PLA] = {IMPLIED => 4} 
  CYCLE_COUNTS[Operation::PLP] = {IMPLIED => 4} 
  CYCLE_COUNTS[Operation::ROL] = {ACCUMULATOR => 2, ZERO_PAGE => 5, ZERO_PAGE_X_INDEXED => 6, ABSOLUTE => 6, ABSOLUTE_X_INDEXED => 7}
  CYCLE_COUNTS[Operation::ROR] = {ACCUMULATOR => 2, ZERO_PAGE => 5, ZERO_PAGE_X_INDEXED => 6, ABSOLUTE => 6, ABSOLUTE_X_INDEXED => 7} 
  CYCLE_COUNTS[Operation::RTI] = {IMPLIED => 6} 
  CYCLE_COUNTS[Operation::RTS] = {IMPLIED => 6} 
  CYCLE_COUNTS[Operation::SBC] = {IMMEDIATE => 2, ZERO_PAGE => 3, ZERO_PAGE_X_INDEXED => 4, ABSOLUTE => 4, ABSOLUTE_X_INDEXED => 4, ABSOLUTE_Y_INDEXED => 4, PRE_INDEXED_INDIRECT => 6, POST_INDEXED_INDIRECT => 5}
  CYCLE_COUNTS[Operation::SEC] = {IMPLIED => 2} 
  CYCLE_COUNTS[Operation::SED] = {IMPLIED => 2} 
  CYCLE_COUNTS[Operation::SEI] = {IMPLIED => 2} 
  CYCLE_COUNTS[Operation::STA] = {ZERO_PAGE => 3, ZERO_PAGE_X_INDEXED => 4, ABSOLUTE => 4, ABSOLUTE_X_INDEXED => 5, ABSOLUTE_Y_INDEXED => 5, PRE_INDEXED_INDIRECT => 6, POST_INDEXED_INDIRECT => 6} 
  CYCLE_COUNTS[Operation::STX] = {ZERO_PAGE => 3, ZERO_PAGE_Y_INDEXED => 4, ABSOLUTE => 4}
  CYCLE_COUNTS[Operation::STY] = {ZERO_PAGE => 3, ZERO_PAGE_X_INDEXED => 4, ABSOLUTE => 4}
  CYCLE_COUNTS[Operation::TAX] = {IMPLIED => 2} 
  CYCLE_COUNTS[Operation::TAY] = {IMPLIED => 2} 
  CYCLE_COUNTS[Operation::TSX] = {IMPLIED => 2} 
  CYCLE_COUNTS[Operation::TXA] = {IMPLIED => 2} 
  CYCLE_COUNTS[Operation::TXS] = {IMPLIED => 2} 
  CYCLE_COUNTS[Operation::TYA] = {IMPLIED => 2} 
  
  
  # Byte Count hashes (instruction length) (BYTE_COUNTS[operation][addressing_mode] -> byte_count)
  BYTE_COUNTS = Array.new
  BYTE_COUNTS[Operation::ADC] = {IMMEDIATE => 2, ZERO_PAGE => 2, ZERO_PAGE_X_INDEXED => 2, ABSOLUTE => 3, ABSOLUTE_X_INDEXED => 3, ABSOLUTE_Y_INDEXED => 3, PRE_INDEXED_INDIRECT => 2, POST_INDEXED_INDIRECT => 2}  
  BYTE_COUNTS[Operation::AND] = {IMMEDIATE => 2, ZERO_PAGE => 2, ZERO_PAGE_X_INDEXED => 2, ABSOLUTE => 3, ABSOLUTE_X_INDEXED => 3, ABSOLUTE_Y_INDEXED => 3, PRE_INDEXED_INDIRECT => 2, POST_INDEXED_INDIRECT => 2}
  BYTE_COUNTS[Operation::ASL] = {ACCUMULATOR => 1, ZERO_PAGE => 2, ZERO_PAGE_X_INDEXED => 2, ABSOLUTE => 3, ABSOLUTE_X_INDEXED => 3}
  BYTE_COUNTS[Operation::BCC] = {RELATIVE => 2}
  BYTE_COUNTS[Operation::BCS] = {RELATIVE => 2}
  BYTE_COUNTS[Operation::BEQ] = {RELATIVE => 2}
  BYTE_COUNTS[Operation::BIT] = {ZERO_PAGE => 2, ABSOLUTE => 3}
  BYTE_COUNTS[Operation::BMI] = {RELATIVE => 2}
  BYTE_COUNTS[Operation::BNE] = {RELATIVE => 2}
  BYTE_COUNTS[Operation::BPL] = {RELATIVE => 2}
  BYTE_COUNTS[Operation::BRK] = {IMPLIED => 1}
  BYTE_COUNTS[Operation::BVC] = {RELATIVE => 2}
  BYTE_COUNTS[Operation::BVS] = {RELATIVE => 2}
  BYTE_COUNTS[Operation::CLC] = {IMPLIED => 1}
  BYTE_COUNTS[Operation::CLD] = {IMPLIED => 1}
  BYTE_COUNTS[Operation::CLI] = {IMPLIED => 1}
  BYTE_COUNTS[Operation::CLV] = {IMPLIED => 1}  
  BYTE_COUNTS[Operation::CMP] = {IMMEDIATE => 2, ZERO_PAGE => 2, ZERO_PAGE_X_INDEXED => 2, ABSOLUTE => 3, ABSOLUTE_X_INDEXED => 3, ABSOLUTE_Y_INDEXED => 3, PRE_INDEXED_INDIRECT => 2, POST_INDEXED_INDIRECT => 2}  
  BYTE_COUNTS[Operation::CPX] = {IMMEDIATE => 2, ZERO_PAGE => 2, ABSOLUTE => 3}  
  BYTE_COUNTS[Operation::CPY] = {IMMEDIATE => 2, ZERO_PAGE => 2, ABSOLUTE => 3}
  BYTE_COUNTS[Operation::DEC] = {ZERO_PAGE => 2, ZERO_PAGE_X_INDEXED => 2, ABSOLUTE => 3, ABSOLUTE_X_INDEXED => 3}
  BYTE_COUNTS[Operation::DEX] = {IMPLIED => 1}
  BYTE_COUNTS[Operation::DEY] = {IMPLIED => 1} 
  BYTE_COUNTS[Operation::EOR] = {IMMEDIATE => 2, ZERO_PAGE => 2, ZERO_PAGE_X_INDEXED => 2, ABSOLUTE => 3, ABSOLUTE_X_INDEXED => 3, ABSOLUTE_Y_INDEXED => 3, PRE_INDEXED_INDIRECT => 2, POST_INDEXED_INDIRECT => 2}
  BYTE_COUNTS[Operation::INC] = {ZERO_PAGE => 2, ZERO_PAGE_X_INDEXED => 2, ABSOLUTE => 3, ABSOLUTE_X_INDEXED => 3}
  BYTE_COUNTS[Operation::INX] = {IMPLIED => 1}
  BYTE_COUNTS[Operation::INY] = {IMPLIED => 1} 
  BYTE_COUNTS[Operation::JMP] = {ABSOLUTE => 3, INDIRECT => 3}
  BYTE_COUNTS[Operation::JSR] = {ABSOLUTE => 3}
  BYTE_COUNTS[Operation::LDA] = {IMMEDIATE => 2, ZERO_PAGE => 2, ZERO_PAGE_X_INDEXED => 2, ABSOLUTE => 3, ABSOLUTE_X_INDEXED => 3, ABSOLUTE_Y_INDEXED => 3, PRE_INDEXED_INDIRECT => 2, POST_INDEXED_INDIRECT => 2}
  BYTE_COUNTS[Operation::LDX] = {IMMEDIATE => 2, ZERO_PAGE => 2, ZERO_PAGE_Y_INDEXED => 2, ABSOLUTE => 3, ABSOLUTE_Y_INDEXED => 3}
  BYTE_COUNTS[Operation::LDY] = {IMMEDIATE => 2, ZERO_PAGE => 2, ZERO_PAGE_X_INDEXED => 2, ABSOLUTE => 3, ABSOLUTE_X_INDEXED => 3}
  BYTE_COUNTS[Operation::LSR] = {ACCUMULATOR => 1, ZERO_PAGE => 2, ZERO_PAGE_X_INDEXED => 2, ABSOLUTE => 3, ABSOLUTE_X_INDEXED => 3}
  BYTE_COUNTS[Operation::NOP] = {IMPLIED => 1} 
  BYTE_COUNTS[Operation::ORA] = {IMMEDIATE => 2, ZERO_PAGE => 2, ZERO_PAGE_X_INDEXED => 2, ABSOLUTE => 3, ABSOLUTE_X_INDEXED => 3, ABSOLUTE_Y_INDEXED => 3, PRE_INDEXED_INDIRECT => 2, POST_INDEXED_INDIRECT => 2}
  BYTE_COUNTS[Operation::PHA] = {IMPLIED => 1} 
  BYTE_COUNTS[Operation::PHP] = {IMPLIED => 1} 
  BYTE_COUNTS[Operation::PLA] = {IMPLIED => 1} 
  BYTE_COUNTS[Operation::PLP] = {IMPLIED => 1} 
  BYTE_COUNTS[Operation::ROL] = {ACCUMULATOR => 1, ZERO_PAGE => 2, ZERO_PAGE_X_INDEXED => 2, ABSOLUTE => 3, ABSOLUTE_X_INDEXED => 3}
  BYTE_COUNTS[Operation::ROR] = {ACCUMULATOR => 1, ZERO_PAGE => 2, ZERO_PAGE_X_INDEXED => 2, ABSOLUTE => 3, ABSOLUTE_X_INDEXED => 3} 
  BYTE_COUNTS[Operation::RTI] = {IMPLIED => 1} 
  BYTE_COUNTS[Operation::RTS] = {IMPLIED => 1} 
  BYTE_COUNTS[Operation::SBC] = {IMMEDIATE => 2, ZERO_PAGE => 2, ZERO_PAGE_X_INDEXED => 2, ABSOLUTE => 3, ABSOLUTE_X_INDEXED => 3, ABSOLUTE_Y_INDEXED => 3, PRE_INDEXED_INDIRECT => 2, POST_INDEXED_INDIRECT => 2}
  BYTE_COUNTS[Operation::SEC] = {IMPLIED => 1} 
  BYTE_COUNTS[Operation::SED] = {IMPLIED => 1} 
  BYTE_COUNTS[Operation::SEI] = {IMPLIED => 1} 
  BYTE_COUNTS[Operation::STA] = {ZERO_PAGE => 2, ZERO_PAGE_X_INDEXED => 2, ABSOLUTE => 3, ABSOLUTE_X_INDEXED => 3, ABSOLUTE_Y_INDEXED => 3, PRE_INDEXED_INDIRECT => 2, POST_INDEXED_INDIRECT => 2} 
  BYTE_COUNTS[Operation::STX] = {ZERO_PAGE => 2, ZERO_PAGE_Y_INDEXED => 2, ABSOLUTE => 3}
  BYTE_COUNTS[Operation::STY] = {ZERO_PAGE => 2, ZERO_PAGE_X_INDEXED => 2, ABSOLUTE => 3}
  BYTE_COUNTS[Operation::TAX] = {IMPLIED => 1} 
  BYTE_COUNTS[Operation::TAY] = {IMPLIED => 1} 
  BYTE_COUNTS[Operation::TSX] = {IMPLIED => 1} 
  BYTE_COUNTS[Operation::TXA] = {IMPLIED => 1} 
  BYTE_COUNTS[Operation::TXS] = {IMPLIED => 1} 
  BYTE_COUNTS[Operation::TYA] = {IMPLIED => 1} 
end