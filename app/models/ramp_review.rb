class RampReview < ActiveRecord::Base
  self.abstract_class = true

  attr_reader :saving_review

  enum option_selected: {
    supplemental_claim: "supplemental_claim",
    higher_level_review: "higher_level_review",
    higher_level_review_with_hearing: "higher_level_review_with_hearing",
    appeal: "appeal"
  }

  END_PRODUCT_DATA_BY_OPTION = {
    "supplemental_claim" => { code: "683SCRRRAMP", modifier: "683" },
    "higher_level_review" => { code: "682HLRRRAMP", modifier: "682" },
    "higher_level_review_with_hearing" => { code: "682HLRRRAMP", modifier: "682" }
  }.freeze

  END_PRODUCT_STATION = "397".freeze # AMC

  validates :receipt_date, :option_selected, presence: { message: "blank" }, if: :saving_review

  # Allows us to enable certain validations only when saving the review
  def start_review!
    @saving_review = true
  end
end
