# To change this template, choose Tools | Templates
# and open the template in the editor.

module PPUHelper
  PATTERN_TABLE_BIT_MASK = [0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01]
  PATTERN_TABLE_BYTE1_BIT_SHIFT = [7, 6, 5, 4, 3, 2, 1, 0]
  PATTERN_TABLE_BYTE2_BIT_SHIFT = [6, 5, 4, 3, 2, 1, 0, -1]
  ATTRIBUTE_TABLE_BIT_MASK = [0x03, 0x0C, 0x30, 0xC0]
  ATTRIBUTE_TABLE_BIT_SHIFT = [-2, 0, 2, 4]

  def initialize
  end

  def get_tile_index(scanline, scanline_cycle)
    return (((scanline / 8).floor) * 32) + (scanline_cycle / 8).floor
  end

  def get_pattern_table_byte1_index(pattern_table_index, scanline)
    return (pattern_table_index * 16) + (scanline % 8)
  end

  def get_pattern_table_byte2_index(pattern_table_index, scanline)
    return ((pattern_table_index * 16) + 8) + (scanline % 8)
  end

  def get_attribute_table_index(tile_index)
    result = 0
    result += ((tile_index / 128).floor * 8)  # Row of attribute table 'grids'
    result += ((tile_index % 32) / 4).floor
    return result
  end

  def get_attribute_table_square(tile_index)
    square = 0
    square = 2 if (tile_index % 128 >= 64)
    square += 1 if (tile_index % 4 >= 2)
    return square
  end

end
