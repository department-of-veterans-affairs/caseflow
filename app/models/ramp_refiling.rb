class RampRefiling < RampReview
  belongs_to :ramp_election

  validate :validate_receipt_date, :validate_option_selected

  def election_receipt_date
    ramp_election && ramp_election.receipt_date
  end

  def validate_receipt_date
    return unless receipt_date && ramp_election

    if election_receipt_date > receipt_date
      errors.add(:receipt_date, "before_ramp_receipt_date")
    else
      validate_receipt_date_not_in_future
    end
  end

  def validate_option_selected
    return unless option_selected && ramp_election

    if ramp_election.higher_level_review? && higher_level_review?
      errors.add(:option_selected, "higher_level_review_invalid")
    end
  end
end
