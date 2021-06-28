# frozen_string_literal: true

# This is for updating the claim label for end products established from Caseflow

class EndProductUpdate < CaseflowRecord
  include BgsService

  belongs_to :end_product_establishment, optional: false
  belongs_to :original_decision_review, polymorphic: true, optional: false
  belongs_to :user, optional: false

  delegate :request_issues, :claim_date, :benefit_type_code, :payee_code, :modifier, :veteran_file_number,
           to: :end_product_establishment

  enum status: { success: "success", error: "error" }

  class UpdateClaimFailedInVBMS < StandardError; end

  def perform!
    transaction do
      update_bgs_claim
      end_product_establishment.update(code: new_code)
      update_correction_type
      update_issue_type
      update_benefit_type
    end
  rescue StandardError => error
    update!(error: error, status: "error")
    raise error
  end

  private

  def update_bgs_claim
    response = bgs.update_benefit_claim(
      veteran_file_number: veteran_file_number,
      payee_code: payee_code,
      claim_date: claim_date,
      benefit_type_code: benefit_type_code,
      modifier: modifier,
      new_code: new_code
    )

    if response[:return_message] != "A benefit claim has been changed"
      fail UpdateClaimFailedInVBMS, response[:return_message]
    end
  end

  def update_correction_type
    correction_type = new_code_hash[:correction_type]
    return if correction_type == old_code_hash[:correction_type]

    request_issues.update(correction_type: correction_type)
  end

  def update_issue_type
    issue_type = new_code_hash[:issue_type]
    return if issue_type == old_code_hash[:issue_type]

    (issue_type == "rating") ? update_issue_type_to_rating : update_issue_type_to_nonrating
  end

  def update_benefit_type
    benefit_type = new_code_hash[:benefit_type]
    return if benefit_type == old_code_hash[:benefit_type]

    request_issues.update(benefit_type: benefit_type)
    update_decision_review_benefit_type(benefit_type)
  end

  def update_issue_type_to_nonrating
    request_issues.each do |ri|
      ri.update(
        type: "NonratingRequestIssue",
        nonrating_issue_category: unknown_nonrating_issue_category,
        nonrating_issue_description: ri.edited_description.presence || ri.contested_issue_description
      )
    end
  end

  def update_issue_type_to_rating
    request_issues.each do |ri|
      ri.update(
        type: "RatingRequestIssue",
        edited_description: ri.nonrating_issue_description
      )
    end
  end

  # If a decision review ends up with multiple end products that have different benefit types, this will move the
  # current EP and its issues onto a separate "claim review stream"
  def update_decision_review_benefit_type(new_benefit_type)
    if original_decision_review.end_product_establishments.count > 1
      review_stream = original_decision_review.find_or_create_stream!(new_benefit_type)
      end_product_establishment.update(source_id: review_stream.id)
      request_issues.update_all(decision_review_id: review_stream.id)
    else
      original_decision_review.update(benefit_type: new_benefit_type)
    end
  end

  def old_code_hash
    Constants.EP_CLAIM_TYPES.to_h[original_code.to_sym]
  end

  def new_code_hash
    Constants.EP_CLAIM_TYPES.to_h[new_code.to_sym]
  end

  def unknown_nonrating_issue_category
    Constants.ISSUE_CATEGORIES.compensation.find { |cat| cat.include?("Unknown") }
  end
end
