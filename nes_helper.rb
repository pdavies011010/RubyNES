class NESHelper
  
  def NESHelper.split_array(value)
    # Will split a one-dimensional array into two arrays
    return value if (value.size == nil || value.size < 2)
    
    new_size = value.size / 2
    result = Array.new(2)
    
    result[0] = value[0...new_size]
    result[1] = value[new_size...value.size]
    
    return result
  end
end