class RampRefiling < RampReview
  class ContentionCreationFailed < StandardError; end

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
    # If there are no contentions to create, don't create the end product either
    return nil if contention_descriptions_to_create.empty?

    create_end_product!
    create_contentions_on_new_end_product!
  end

  def election_receipt_date
    ramp_election && ramp_election.receipt_date
  end

  def needs_end_product?
    option_selected != "appeal"
  end

  private

  def contention_descriptions_to_create
    @contention_descriptions_to_create ||=
      issues.where(contention_reference_id: nil).order(:description).pluck(:description)
  end

  # VBMS will return ALL contentions on a end product when you create contentions,
  # not just the ones that were just created. This method assumes there are no
  # pre-existing contentions on the end product. Since it was also just created.
  def create_contentions_on_new_end_product!
    # Load all the issues so we can match them in memory
    issues.all.tap do |issues|

      # Currently not making any assumptions about the order in which VBMS returns
      # the created contentions. Instead find the issue by matching text.
      create_contentions_in_vbms.each do |contention|
        matching_issue = issues.find { |issue| issue.description == contention.text }
        matching_issue && matching_issue.update!(contention_reference_id: contention.id)
      end

      fail ContentionCreationFailed if issues.any? { |issue| !issue.contention_reference_id }
    end
  end

  def create_contentions_in_vbms
    VBMSService.create_contentions!(
      veteran_file_number: veteran_file_number,
      claim_id: end_product_reference_id,
      contention_descriptions: contention_descriptions_to_create
    )
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
