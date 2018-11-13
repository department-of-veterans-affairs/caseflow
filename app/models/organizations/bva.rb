class Bva < Organization
  def self.singleton
    Bva.first || Bva.create!(name: "Board of Veterans' Appeals")
  end
end
