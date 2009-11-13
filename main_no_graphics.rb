class MainNoGraphics
  def initialize(rom_file)
    # Now initialize the actual NES emulator
    @nes = NES.new
    @nes.load_rom(rom_file)

    @nes.power_on
    loop do
      @nes.run_one_frame
    end
  end
end
