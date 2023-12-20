# frozen_string_literal: true

class QualityReview < Organization
  def self.singleton
    QualityReview.first || QualityReview.create(name: "Quality Review", url: "quality-review")
  end
end
