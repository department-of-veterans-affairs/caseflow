class RampElection < ActiveRecord::Base
  OPTIONS = %w(
    supplemental_claim
    higher_level_review
    higher_level_review_with_hearing
    withdraw
  ).freeze

  validates :option_selected, inclusion: { in: OPTIONS }, allow_nil: true
end
