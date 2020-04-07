# frozen_string_literal: true

class CaseReview < Organization
  class << self
    def singleton
      CaseReview.first || CaseReview.create(name: "Case Review", url: "case-review")
    end
  end
end
