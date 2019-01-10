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

  # Attorneys will be entering in a description of the decision manually for appeals
  before_save :calculate_and_set_description, unless: :appeal?

  def self.granted
    # TODO: "allowed" is the disposition for BVA grants, not necessarily the disposition for granted HLRs and SCs
    #       we need to add that
    where(disposition: "allowed")
  end

  def approx_decision_date
    profile_date ? profile_date.to_date : end_product_last_action_date
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

  def finalized?
    decision_review.is_a?(Appeal) && decision_review.outcoded?
  end

  def ui_hash
    {
      id: id,
      requestIssueId: request_issues&.first&.id,
      description: description,
      disposition: disposition
    }
  end

  private

  def calculate_and_set_description
    self.description ||= calculate_description
  end

  def calculate_description
    return decision_text if decision_text
    return nil unless associated_request_issue

    "#{disposition}: #{associated_request_issue.description}"
  end

  def associated_request_issue
    return unless request_issues.any?

    request_issues.first
  end

  def appeal?
    decision_review_type == Appeal.to_s
  end
end
