class DecisionIssue < ApplicationRecord
  validates :disposition, inclusion: { in: Constants::ISSUE_DISPOSITIONS_BY_ID.keys.map(&:to_s) },
                          if: :appeal?
  validates :benefit_type, inclusion: { in: Constants::BENEFIT_TYPES.keys.map(&:to_s) },
                           if: :appeal?
  validates :description, presence: true, if: :appeal?
  has_many :request_decision_issues, dependent: :destroy
  has_many :request_issues, through: :request_decision_issues
  has_many :remand_reasons, dependent: :destroy
  belongs_to :decision_review, polymorphic: true

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
