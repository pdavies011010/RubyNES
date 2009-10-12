#require "profile"
require "main"
require "debugger"

# Initialize Debugger as a global constant 'DEBUG'. Turn Debugging off by default.
debugging=false
DEBUG = Debugger.new(debugging)

MAIN = Main.new
