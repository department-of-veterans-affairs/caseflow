class RampRefiling < RampReview
  belongs_to :ramp_election

  validate :validate_receipt_date, :validate_option_selected

  def create_issues!(source_issue_ids:)
    issues.destroy_all unless issues.empty?

    source_issue_ids.map { |issue_id| issues.create!(source_issue_id: issue_id) }
  end

  # We have no solution to make the combination of these operations atomic, or guarantee
  # eventual consistency. So for now, if the create contentions request fails, we will be in an
  # inconsistent state and must recover manually
  def create_end_product_and_contentions!
    create_end_product!
    create_contentions!
  end

  def election_receipt_date
    ramp_election && ramp_election.receipt_date
  end

  def needs_end_product?
    option_selected != "appeal"
  end

  private

  def create_contentions!
    # TODO: Create contentions on the end product from the issues
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
