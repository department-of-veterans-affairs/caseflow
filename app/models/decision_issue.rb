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
  has_one :effectuation, class_name: "BoardGrantEffectuation", foreign_key: :granted_decision_issue_id

  def self.granted
    # TODO: "allowed" is the disposition for BVA grants, not necessarily the disposition for granted HLRs and SCs
    #       we need to add that
    where(disposition: "allowed")
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

  def destroy_on_removed_request_issue(request_issue_id)
    # destroy if the request issue is deleted and there are no other request issues associated
    destroy if request_issues.length == 1 && request_issues.first.id == request_issue_id
  end

  # Since nonrating issues require specialization to process, if any associated request issue is nonrating
  # the entire decision issue gets set to nonrating
  def rating?
    request_issues.none?(&:nonrating?)
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
