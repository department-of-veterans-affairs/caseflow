# frozen_string_literal: true

class BvaIntake < Organization
  class << self
    def singleton
      BvaIntake.first || BvaIntake.create(name: "BVA Intake", url: "bva-intake")
    end
  end
end
