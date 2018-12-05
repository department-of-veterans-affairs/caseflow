class DecisionIssue < ApplicationRecord
  validates :disposition, inclusion: { in: Constants::ISSUE_DISPOSITIONS_BY_ID.keys.map(&:to_s) },
                          allow_nil: true, if: :appeal?
  has_many :request_decision_issues, dependent: :destroy
  has_many :request_issues, through: :request_decision_issues
  has_many :remand_reasons, dependent: :destroy
  belongs_to :decision_review, polymorphic: true

  def title_of_active_review
    request_issue = RequestIssue.find_active_by_contested_decision_id(id)
    request_issue.review_title if request_issue
  end

  def source_higher_level_review
    return unless decision_review
    decision_review.is_a?(HigherLevelReview) ? decision_review.id : nil
  end

  def approx_decision_date
    profile_date ? profile_date.to_date : end_product_last_action_date
  end

  private

  def appeal?
    decision_review_type == Appeal.to_s
  end
end
