module PageCacheFu
  private

  def self.mode_match(mode1, mode2)
    mode1, mode2 = mode1.to_s, mode2.to_s
    length = [mode1.size,mode2.size].max
    mode1, mode2 = ("%0#{length}d" % mode1), ("%0#{length}d" % mode2)
    match = true
    0.upto(length-1) do |i|
      unless mode1[i].to_i & mode2[i].to_i == mode2[i].to_i
        match = false
        break
      end
    end
    return match
  end

end
