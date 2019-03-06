# frozen_string_literal: true

class Translation < Organization
  def self.singleton
    Translation.first || Translation.create(name: "Translation", url: "translation")
  end
end
