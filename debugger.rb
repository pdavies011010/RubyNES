require "logger"

class Debugger
  attr_accessor :debugging, :io_reader

  
  def initialize(debugging)
    @debugging = debugging
    @commands = {}
    @logger = Logger.new("rnes.log")
  end
  
  def debug_print(val)
    if (@debugging)
      print val  # For now just print to the console
    end
  end
  
  def debug_log(val)
    if (@debugging)
      @logger << val
    end
  end
  
  def debug_addcommand(name, proc)
    # This method receives two variables, a name (string)
    # and a proc (Proc) to call. The proc should receive one
    # string parameter (which can be a delimited list but the 
    # proc itself must handle that). 
    @commands[name] = proc
  end
  
  def debug_getcommand
    result = false # Variable indicating whether a command was received
    
    if (@debugging) 
      # Eliminate any pre-existing input
      @io_reader.flush

      print "\nCommand>> "
      command = @io_reader.gets.chop
      
      if command == "?"
        print "Commands: #{@commands.keys.sort.join(', ')}\n"
        result = true
      elsif not command.nil? and not command.empty?
        debug_execcommand(command.split[0].downcase, command.split[1])
        result = true
      end
    end
    
    return result
  end
  
  def debug_getcommands
    command_received = nil
    command_received = debug_getcommand until (command_received == false)
  end
  
  def debug_execcommand(name, param)
    if (@commands[name] != nil)
      @commands[name].call(param)
    end
  end
  
  # Convert a numeric value into a hex string with preceding "0x"
  def num2hex(val)
    return "0x" + val.to_s(16).upcase
  end
  
  def enable_debugging
    @debugging = true
    debug_print "Debugging Enabled.\n"
  end
  
  def disable_debugging
    @debugging = false
  end

  def is_debugging?
    return @debugging
  end
end