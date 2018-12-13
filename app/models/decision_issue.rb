class DecisionIssue < ApplicationRecord
  validates :disposition, inclusion: { in: Constants::ISSUE_DISPOSITIONS_BY_ID.keys.map(&:to_s) },
                          allow_nil: true, if: :appeal?
  validates :benefit_type, inclusion: { in: Constants::BENEFIT_TYPES.keys.map(&:to_s) },
                           allow_nil: true, if: :appeal?
  has_many :request_decision_issues, dependent: :destroy
  has_many :request_issues, through: :request_decision_issues
  has_many :remand_reasons, dependent: :destroy
  belongs_to :decision_review, polymorphic: true

  def title_of_active_review
    request_issue = RequestIssue.find_active_by_contested_decision_id(id)
    request_issue&.review_title
  end

  def source_higher_level_review
    return unless decision_review
    decision_review.is_a?(HigherLevelReview) ? decision_review.id : nil
  end

  def approx_decision_date
    profile_date ? profile_date.to_date : end_product_last_action_date
  end

  def formatted_description
    return description if description
    (associated_request_issue&.nonrating?) ? nonrating_description : rating_description
  end

  def issue_category
    associated_request_issue&.issue_category
  end

  private

  def associated_request_issue
    return unless request_issues.any?
    request_issues.first
  end

  def nonrating_description
    "#{disposition}: #{issue_category} - #{associated_request_issue.description}"
  end

  def rating_description
    return decision_text unless associated_request_issue&.notes
    "#{decision_text}. Notes: #{associated_request_issue.notes}"
  end

  def appeal?
    decision_review_type == Appeal.to_s
  end
end
