#require "profile"
require "debugger"
require "main"
require "main_no_graphics"

command_line_file = ARGV.shift
command_line_debug = ARGV.shift

# Initialize Debugger as a global constant 'DEBUG'. Turn Debugging off by default.
debugging=false

# Command Line: Enable Debugging = second argument
if !command_line_debug.nil? and !command_line_debug.empty?
  debugging = command_line_debug.match("^[tT].*") ? true : false
end

DEBUG = Debugger.new(debugging)

file = command_line_file

# Load standard frontend
MAIN = Main.new file

# Load text-only frontend
#MAIN = MainNoGraphics.new file
