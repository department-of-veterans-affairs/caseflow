class DecisionIssue < ApplicationRecord
  validates :disposition, inclusion: { in: Constants::ISSUE_DISPOSITIONS_BY_ID.keys.map(&:to_s) },
                          allow_nil: true, if: :appeal?
  has_many :request_decision_issues, dependent: :destroy
  has_many :request_issues, through: :request_decision_issues
  has_many :remand_reasons, dependent: :destroy
  belongs_to :decision_review, polymorphic: true

  def approx_decision_date
    profile_date ? profile_date.to_date : end_product_last_action_date
  end

  private

  def appeal?
    decision_review_type == Appeal.to_s
  end
end
