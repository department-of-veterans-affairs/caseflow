class RampRefiling < RampReview
  class ContentionCreationFailed < StandardError; end

  before_validation :clear_appeal_docket_if_not_appeal

  validate :validate_receipt_date, :validate_option_selected
  validates :appeal_docket, presence: { message: "blank" }, if: :appeal?

  enum appeal_docket: {
    direct_review: "direct_review",
    evidence_submission: "evidence_submission",
    hearing: "hearing"
  }

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

    # TODO: consider using create_or_connect_end_product! instead to make this atomic
    # however this has further implications here if there are already contentions on
    # the end product being connected.
    establish_end_product!

    create_contentions_on_new_end_product!
  end

  def election_receipt_date
    ramp_elections.map(&:receipt_date).min
  end

  def needs_end_product?
    option_selected != "appeal"
  end

  private

  # TODO: add end product status to ramp_refiling
  def end_product_status
    nil
  end

  def ramp_elections
    RampElection.established.where(veteran_file_number: veteran_file_number).all
  end

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
      claim_id: end_product_establishment.reference_id,
      contention_descriptions: contention_descriptions_to_create
    )
  end

  def validate_receipt_date
    return unless receipt_date && election_receipt_date

    if election_receipt_date > receipt_date
      errors.add(:receipt_date, "before_ramp_receipt_date")
    else
      validate_receipt_date_not_in_future
    end
  end

  def validate_option_selected
    return unless option_selected

    if ramp_elections.any?(&:higher_level_review?) && higher_level_review?
      errors.add(:option_selected, "higher_level_review_invalid")
    end
  end

  # If it's not an appeal, don't bother setting an error, just null it out
  def clear_appeal_docket_if_not_appeal
    self.appeal_docket = nil if option_selected != "appeal"
  end
end
