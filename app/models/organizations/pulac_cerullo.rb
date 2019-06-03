# frozen_string_literal: true

class PulacCerullo < Organization
  def self.singleton
    PulacCerullo.first || PulacCerullo.create(name: "Pulac-Cerullo", url: "pulac-cerullo")
  end

  def next_assignee(_options = {})
    users.first
  end
end
