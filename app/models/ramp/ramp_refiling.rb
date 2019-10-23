# frozen_string_literal: true

class RampRefiling < RampReview
  class ContentionCreationFailed < StandardError; end

  before_validation :clear_appeal_docket_if_not_appeal

  validate :validate_receipt_date, :validate_option_selected
  validates :appeal_docket, presence: { message: "blank" }, if: :appeal?

  enum appeal_docket: {
    direct_review: Constants.AMA_DOCKETS.direct_review,
    evidence_submission: Constants.AMA_DOCKETS.evidence_submission,
    hearing: Constants.AMA_DOCKETS.hearing
  }

  def self.need_to_reprocess
    where(
      establishment_submitted_at: (5.years.ago...1.minute.ago),
      establishment_processed_at: nil
    )
  end

  def create_issues!(source_issue_ids:)
    issues.destroy_all unless issues.empty?

    source_issue_ids.map { |issue_id| issues.create!(source_issue_id: issue_id) }
  end

  def create_end_product_and_contentions!
    # If there are no contentions to create, don't create the end product either
    return nil if contention_descriptions_to_create.empty?

    establish_end_product!(commit: false)

    if create_contentions_on_new_end_product!
      end_product_establishment.commit!
      update!(establishment_processed_at: Time.zone.now)
    end
  end

  def election_receipt_date
    ramp_elections.map(&:receipt_date).min
  end

  def needs_end_product?
    option_selected != "appeal"
  end

  private

  def ramp_elections
    RampElection.established.where(veteran_file_number: veteran_file_number).all
  end

  def contention_descriptions_to_create
    @contention_descriptions_to_create ||=
      issues.where(contention_reference_id: nil).order(:description).map(&:contention_text)
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
        matching_issue = issues.find do |issue|
          issue.contention_text == contention.text && issue.contention_reference_id.nil?
        end
        matching_issue&.update!(contention_reference_id: contention.id)
      end

      fail ContentionCreationFailed if issues.any? { |issue| !issue.contention_reference_id }
    end

    true

    # If an error occurs with creating the contentions in VBMS, swallow the error and don't save
    # the ramp refiling as being processed, we'll retry later.
  rescue StandardError => error
    Raven.capture_exception(error)
    false
  end

  def create_contentions_in_vbms
    VBMSService.create_contentions!(
      veteran_file_number: veteran_file_number,
      claim_id: end_product_establishment.reference_id,
      contentions: contention_descriptions_to_create.map { |desc| { "description": desc } },
      user: intake_processed_by,
      claim_date: receipt_date
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
