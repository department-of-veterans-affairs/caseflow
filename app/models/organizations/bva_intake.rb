# frozen_string_literal: true

class BvaIntake < Organization
  def self.singleton
    BvaIntake.first || BvaIntake.create(name: "Case Review", url: "case-review")
  end
end
