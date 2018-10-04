class QualityReview < Organization
  def self.singleton
    QualityReview.first || QualityReview.create(name: "Quality Review")
  end
end
