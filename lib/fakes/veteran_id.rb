class Fakes::VeteranId
  # Generate fake Veteran IDs

  # Cycle through these prefixes
  @ids = %w(
    516517
    633792
    141102
    117739
    796148
    117362
    149092
    633522
    561349
    796147
  )

  def self.get(index)
    id = num(index) + "000"

    # replace the final X digits of the ID based on the
    # value/length of the index
    id[(id.length - index.to_s.length)..-1] = index.to_s

    # occasionally append "C" or "S"
    ltr = letter(index).to_s
    id.concat(ltr)

    # occasionally shrink IDs with trailing "C"
    return id.last(8) if ltr == "C" && index % 12 == 0
    return id.last(6) if ltr == "C" && index % 3 == 0

    id
  end

  def self.num(index)
    9.downto(1) do |i|
      return @ids[i] if (index + 1) % (i + 1) == 0
    end
    @ids[0]
  end

  def self.letter(index)
    return "C" if index % 6 == 0
    return "S" if index % 3 == 0
  end
end
