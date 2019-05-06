# frozen_string_literal: true

class PulacCurello < Organization
  def self.singleton
    PulacCurello.first || PulacCurello.create(name: "Pulac Curello", url: "pulac-curello")
  end
end
