class DecisionIssue < ApplicationRecord
  validates :benefit_type, inclusion: { in: Constants::BENEFIT_TYPES.keys.map(&:to_s) }
  validates :disposition, presence: true
  validates :end_product_last_action_date, presence: true, unless: :processed_in_caseflow?

  with_options if: :appeal? do
    validates :disposition, inclusion: { in: Constants::ISSUE_DISPOSITIONS_BY_ID.keys.map(&:to_s) }
    validates :diagnostic_code, inclusion: { in: Constants::DIAGNOSTIC_CODE_DESCRIPTIONS.keys.map(&:to_s) },
                                allow_nil: true
  end

  # Attorneys will be entering in a description of the decision manually for appeals
  before_save :calculate_and_set_description, unless: :appeal?

  has_many :request_decision_issues, dependent: :destroy
  has_many :request_issues, through: :request_decision_issues
  has_many :remand_reasons, dependent: :destroy
  belongs_to :decision_review, polymorphic: true
  has_one :effectuation, class_name: "BoardGrantEffectuation", foreign_key: :granted_decision_issue_id
  has_one :contesting_request_issue, class_name: "RequestIssue", foreign_key: "contested_decision_issue_id"

  class AppealDTAPayeeCodeError < StandardError
    def initialize(appeal_id)
      super("Can't create a SC DTA for appeal #{appeal_id} due to missing payee code")
    end
  end

  class << self
    # TODO: These scopes are based only off of Caseflow dispositions, not VBMS dispositions. We probably want
    # to add those, or assess some sort of conversion
    def granted
      where(disposition: "allowed")
    end

    def remanded
      where(disposition: "remanded")
    end

    def not_remanded
      where.not(disposition: "remanded")
    end
  end

  def approx_decision_date
    processed_in_caseflow? ? caseflow_decision_date : claim_review_approx_decision_date
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
    appeal? ? decision_review.outcoded? : disposition.present?
  end

  def ui_hash
    {
      id: id,
      requestIssueId: request_issues&.first&.id,
      description: description,
      disposition: disposition,
      promulgationDate: promulgation_date,
      caseflowDecisionDate: caseflow_decision_date
    }
  end

  def find_or_create_remand_supplemental_claim!
    find_remand_supplemental_claim || create_remand_supplemental_claim!
  end

  def imo?
    remand_reasons.map(&:code).include?("advisory_medical_opinion")
  end

  def contention_text
    Contention.new(description).text
  end

  def api_status_active?
    # this is still being worked on so for the purposes of communicating
    # to the veteran, this decision issue is still considered active
    return true if decision_review.is_a?(Appeal) && disposition == "remanded"

    false
  end

  def api_status_last_action
    return "remand" if disposition == "remanded"

    disposition
  end

  def api_status_last_action_date
    approx_decision_date
  end

  def disposition_for_status
    "remand" if disposition == "remanded"
    disposition
  end

  def description_for_status
    description = fetch_diagnostic_code_status_description(diagnostic_code)
    return description if description

    "#{benefit_type.capitalize} issue"
  end

  private

  def fetch_diagnostic_code_status_description(diagnostic_code)
    if diagnostic_code && Constants::DIAGNOSTIC_CODE_DESCRIPTIONS[diagnostic_code]
      description = Constants::DIAGNOSTIC_CODE_DESCRIPTIONS[diagnostic_code]["status_description"]
      description[0] = description[0].upcase
      description
    end
  end

  def processed_in_caseflow?
    decision_review.processed_in_caseflow?
  end

  def claim_review_approx_decision_date
    # there's an end_product_last_action_date when decision issues are created from eps
    # but only a promulgation date when decision issues are created from noncomp
    if profile_date
      profile_date.to_date
    else
      end_product_last_action_date || (promulgation_date&.to_date)
    end
  end

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

  def veteran_file_number
    decision_review.veteran_file_number
  end

  def appeal?
    decision_review_type == Appeal.to_s
  end

  def prior_payee_code
    latest_ep = decision_review.veteran
      .find_latest_end_product_by_claimant(decision_review.claimants.first)

    if latest_ep.nil? || latest_ep.payee_code.nil?
      # mark appeal as failed
      decision_review.update_error!("DTA SC creation failed")
      fail AppealDTAPayeeCodeError, decision_review.id
    end

    latest_ep.payee_code
  end

  def find_remand_supplemental_claim
    SupplementalClaim.find_by(
      veteran_file_number: veteran_file_number,
      decision_review_remanded: decision_review,
      benefit_type: benefit_type
    )
  end

  def create_remand_supplemental_claim!
    # Checking our assumption that approx_decision_date will always be populated for Decision Issues
    fail "approx_decision_date is required to create a DTA Supplemental Claim" unless approx_decision_date

    sc = SupplementalClaim.create!(
      veteran_file_number: veteran_file_number,
      decision_review_remanded: decision_review,
      benefit_type: benefit_type,
      legacy_opt_in_approved: decision_review.legacy_opt_in_approved,
      veteran_is_not_claimant: decision_review.veteran_is_not_claimant,
      receipt_date: approx_decision_date
    )

    sc.create_claimants!(
      participant_id: decision_review.claimant_participant_id,
      payee_code: prior_payee_code
    )

    sc
  rescue AppealDTAPayeeCodeError
    # mark SC as failed
    sc.update_error!("No payee code")
    raise
  end
end
