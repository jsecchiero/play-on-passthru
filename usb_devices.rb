require 'libusb'

class USB

  def initialize
    usb = LIBUSB::Context.new
    @devices = usb.devices
    @usbs = []
  end

  def show_ids
    @devices.each do |dev|
      @usbs << "%04x:%04x" % [dev.idVendor, dev.idProduct]
    end
    return @usbs
  end
end
