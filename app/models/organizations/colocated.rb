class Colocated < Organization
  def self.singleton
    Colocated.first || Colocated.create(name: "VLJ Support Staff", url: "vlj-support-staff")
  end
end
