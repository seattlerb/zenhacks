
class Machine
  def self.big_endian?
    [1].pack('L')[-1] == 1
  end

  def self.little_endian?
    not big_endian?
  end

  def self.byte_swapped?
    swapped = [0x01020304].pack('L')
    ! (swapped[0] == 1 && swapped[1] == 2 && swapped[2] == 3 && swapped[3] == 4)
  end

  def self.bits_per_long
    [42].pack('L').size * 8
  end
end
