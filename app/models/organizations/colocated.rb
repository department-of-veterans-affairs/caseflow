class Colocated < Organization
  def self.singleton
    Colocated.first || Colocated.create(name: "VLJ Support Management", url: "vlj-support-management")
  end
end
