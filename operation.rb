# Constant (enum-ish) definition of operations
module Operation
  ADC = 1
  AND = 2
  ASL = 3
  BCC = 4
  BCS = 5
  BEQ = 6
  BIT = 7
  BMI = 8
  BNE = 9
  BPL = 10
  BRK = 11
  BVC = 12
  BVS = 13
  CLC = 14
  CLD = 15
  CLI = 16
  CLV = 17
  CMP = 18
  CPX = 19
  CPY = 20
  DEC = 21
  DEX = 22
  DEY = 23
  EOR = 24
  INC = 25
  INX = 26
  INY = 27
  JMP = 28
  JSR = 29
  LDA = 30
  LDX = 31
  LDY = 32
  LSR = 33
  NOP = 34
  ORA = 35
  PHA = 36
  PHP = 37
  PLA = 38
  PLP = 39
  ROL = 40
  ROR = 41
  RTI = 42
  RTS = 43  
  SBC = 44
  SEC = 45
  SED = 46
  SEI = 47
  STA = 48
  STX = 49
  STY = 50
  TAX = 51
  TAY = 52
  TSX = 53
  TXA = 54
  TXS = 55
  TYA = 56
  
  def Operation.name(op)
    result = ""
    case op
      when ADC
      result = "ADC"
      when AND
      result = "AND"
      when ASL
      result = "ASL"
      when BCC
      result = "BCC"
      when BCS
      result = "BCS"
      when BEQ
      result = "BEQ"
      when BIT
      result = "BIT"
      when BMI
      result = "BMI"
      when BNE
      result = "BNE"
      when BPL
      result = "BPL"
      when BRK
      result = "BRK"
      when BVC
      result = "BVC"
      when BVS
      result = "BVS"
      when CLC
      result = "CLC"
      when CLD
      result = "CLD"
      when CLI
      result = "CLI"
      when CLV
      result = "CLV"
      when CMP
      result = "CMP"
      when CPX
      result = "CPX"
      when CPY
      result = "CPY"
      when DEC
      result = "DEC"
      when DEX
      result = "DEX"
      when DEY
      result = "DEY"
      when EOR
      result = "EOR"
      when INC
      result = "INC"
      when INX
      result = "INX"
      when INY 
      result = "INY"
      when JMP
      result = "JMP"
      when JSR
      result = "JSR"
      when LDA
      result = "LDA"
      when LDX
      result = "LDX"
      when LDY
      result = "LDY"
      when LSR
      result = "LSR"
      when NOP
      result = "NOP"
      when ORA
      result = "ORA"
      when PHA
      result = "PHA"
      when PHP
      result = "PHP"
      when PLA
      result = "PLA"
      when PLP
      result = "PLP"
      when ROL
      result = "ROL"
      when ROR
      result = "ROR"
      when RTI
      result = "RTI"
      when RTS
      result = "RTS"
      when SBC
      result = "SBC"
      when SEC
      result = "SEC"
      when SED
      result = "SED"
      when SEI
      result = "SEI"
      when STA
      result = "STA"
      when STX
      result = "STX"
      when STY
      result = "STY"
      when TAX
      result = "TAX"
      when TAY
      result = "TAY"
      when TSX
      result = "TSX"
      when TXA
      result = "TXA"
      when TXS
      result = "TXS"
      when TYA
      result = "TYA"
    end
    return result
  end
end