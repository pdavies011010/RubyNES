
#Constant (enum-ish) definition of adressing modes
module AddressingMode
  IMMEDIATE = 1
  ABSOLUTE = 2
  ZERO_PAGE = 3
  IMPLIED = 4
  ACCUMULATOR = 5
  ZERO_PAGE_X_INDEXED = 6
  ZERO_PAGE_Y_INDEXED = 7
  ABSOLUTE_X_INDEXED = 8
  ABSOLUTE_Y_INDEXED = 9
  INDIRECT = 10
  PRE_INDEXED_INDIRECT = 11
  POST_INDEXED_INDIRECT = 12
  RELATIVE = 13
  
  def AddressingMode.name(mode)
    result = ""
    case mode
      when IMMEDIATE
      result = "Immediate"
      when ABSOLUTE
      result = "Absolute"
      when ZERO_PAGE
      result = "Zero-Page"
      when IMPLIED
      result = "Implied"
      when ACCUMULATOR
      result = "Accumulator"
      when ZERO_PAGE_X_INDEXED
      result = "Zero-Page X-Indexed"
      when ZERO_PAGE_Y_INDEXED
      result = "Zero-Page Y-Indexed"
      when ABSOLUTE_X_INDEXED
      result = "Absolute X-Indexed"
      when ABSOLUTE_Y_INDEXED
      result = "Absolute Y-Indexed"
      when INDIRECT
      result = "Indirect"
      when PRE_INDEXED_INDIRECT
      result = "Pre-Indexed Indirect"
      when POST_INDEXED_INDIRECT
      result = "Post-Indexed Indirect"
      when RELATIVE
      result = "Relative"
    end
    return result
  end
end