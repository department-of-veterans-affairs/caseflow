# frozen_string_literal: true

# This is for updating the claim label for end products established from Caseflow

class EndProductUpdate < CaseflowRecord
  belongs_to :end_product_establishment
  belongs_to :original_decision_review, polymorphic: true
  belongs_to :user

  enum status: { success: "success", error: "error" }

  def perform!
    transaction do
      end_product_establishment.update(code: new_code)
      update_correction_type
      update_issue_type
    end
  end

  private

  def update_correction_type
    correction_type = new_code_hash[:correction_type]
    return if correction_type == old_code_hash[:correction_type]

    end_product_establishment.request_issues.update(correction_type: correction_type)
  end

  def update_issue_type
    issue_type = new_code_hash[:issue_type]
    return if issue_type == old_code_hash[:issue_type]

    type_name = (issue_type == "rating") ? "RatingRequestIssue" : "NonratingRequestIssue"

    end_product_establishment.request_issues.update(type: type_name)
  end

  def old_code_hash
    Constants.EP_CLAIM_TYPES.to_h[original_code.to_sym]
  end

  def new_code_hash
    Constants.EP_CLAIM_TYPES.to_h[new_code.to_sym]
  end
end
