# frozen_string_literal: true

class Colocated < Organization
  def self.singleton
    Colocated.first || Colocated.create(name: "VLJ Support Staff", url: "vlj-support")
  end
end
