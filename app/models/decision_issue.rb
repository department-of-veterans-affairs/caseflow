# frozen_string_literal: true

class DecisionIssue < CaseflowRecord
  include BelongsToPolymorphicAppealConcern
  include HasDecisionReviewUpdatedSince

  validates :benefit_type, inclusion: { in: Constants::BENEFIT_TYPES.keys.map(&:to_s) }
  validates :disposition, presence: true
  validates :end_product_last_action_date, presence: true, unless: :processed_in_caseflow?

  with_options if: :appeal? do
    validates :disposition, inclusion: { in: Constants::ISSUE_DISPOSITIONS_BY_ID.keys.map(&:to_s) }
  end

  # Attorneys will be entering in a description of the decision manually for appeals
  before_save :calculate_and_set_description, unless: :appeal?

  has_many :request_decision_issues, dependent: :destroy
  has_many :request_issues, through: :request_decision_issues
  has_many :remand_reasons, dependent: :destroy

  belongs_to :decision_review, polymorphic: true
  associated_appeal_class(DecisionReview)

  has_one :effectuation, class_name: "BoardGrantEffectuation", foreign_key: :granted_decision_issue_id
  has_many :contesting_request_issues, class_name: "RequestIssue", foreign_key: "contested_decision_issue_id"

  has_many :ama_decision_documents, -> { includes(:ama_decision_issues).references(:decision_issues) },
           through: :ama_appeal, source: :decision_documents

  # NOTE: These are the string identifiers for remand dispositions returned from VBMS.
  #       The characters and encoding are precise so don't change these unless you
  #       know they match VBMS values.

  DIFFERENCE_OF_OPINION = "Difference of Opinion"
  DTA_ERROR = "DTA Error"
  DTA_ERROR_EXAM_MO = "DTA Error - Exam/MO"
  DTA_ERROR_FED_RECS = "DTA Error - Fed Recs"
  DTA_ERROR_OTHER_RECS = "DTA Error - Other Recs"
  DTA_ERROR_PMR = "DTA Error - PMRs"
  REMANDED = "remanded"

  REMAND_DISPOSITIONS = [
    DIFFERENCE_OF_OPINION,
    DTA_ERROR,
    DTA_ERROR_EXAM_MO,
    DTA_ERROR_FED_RECS,
    DTA_ERROR_OTHER_RECS,
    DTA_ERROR_PMR,
    REMANDED
  ].freeze

  # We are using default scope here because we'd like to soft delete decision issues
  # for debugging purposes and to make it easier for developers to filter out
  # soft deleted records
  default_scope { where(deleted_at: nil) }

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
      where(disposition: REMAND_DISPOSITIONS)
    end

    def not_denied
      where.not(disposition: %w[Denied denied])
    end

    def not_remanded
      where.not(disposition: REMAND_DISPOSITIONS)
    end

    def contested
      joins("INNER JOIN request_issues on request_issues.contested_decision_issue_id = decision_issues.id")
    end

    def uncontested
      joins("LEFT JOIN request_issues on decision_issues.id = request_issues.contested_decision_issue_id")
        .where("request_issues.contested_decision_issue_id IS NULL")
    end
  end

  def contesting_remand_request_issue
    contesting_request_issues.find(&:remanded?)
  end

  def soft_delete
    update(deleted_at: Time.zone.now)
    request_decision_issues.update_all(deleted_at: Time.zone.now)
  end

  def approx_decision_date
    processed_in_caseflow? ? caseflow_decision_date : approx_processed_in_vbms_decision_date
  end

  def nonrating_issue_category
    associated_request_issue&.nonrating_issue_category
  end

  def soft_delete_on_removed_request_issue
    # mark as deleted if the request issue is deleted and there are no other request issues associated
    update(deleted_at: Time.zone.now) if request_issues.length == 1
  end

  # Since nonrating issues require specialization to process, if any associated request issue is nonrating
  # the entire decision issue gets set to nonrating
  def rating?
    request_issues.none?(&:nonrating?)
  end

  def finalized?
    appeal? ? decision_review.outcoded? : disposition.present?
  end

  def remanded?
    REMAND_DISPOSITIONS.include?(disposition)
  end

  def serialize
    Intake::DecisionIssueSerializer.new(self).serializable_hash[:data][:attributes]
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
    disposition && REMAND_DISPOSITIONS.include?(disposition)
  end

  def api_status_last_action
    return "remand" if disposition == "remanded"

    disposition
  end

  def api_status_last_action_date
    approx_decision_date.try(&:to_date)
  end

  def api_status_disposition
    "remand" if disposition == "remanded"
    disposition
  end

  def api_status_description
    description = fetch_diagnostic_code_status_description(diagnostic_code)
    return description if description

    "#{benefit_type.capitalize} issue"
  end

  def associated_request_issue
    return unless request_issues.any?

    request_issues.first
  end

  def create_contesting_request_issue!(appeal)
    RequestIssue.find_or_create_by!(
      decision_review: appeal,
      decision_review_type: decision_review_type,
      contested_decision_issue_id: id,
      contested_rating_issue_diagnostic_code: diagnostic_code,
      contested_rating_issue_reference_id: rating_issue_reference_id,
      contested_rating_issue_profile_date: rating_profile_date,
      contested_issue_description: description,
      nonrating_issue_category: nonrating_issue_category,
      benefit_type: benefit_type,
      decision_date: caseflow_decision_date,
      veteran_participant_id: decision_review.veteran.participant_id
    )
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
    decision_review.processed_in_caseflow? || decision_review.tasks.active.any?
  end

  # the decision date is approximate but we need it for timeliness checks.
  # see also ContestableIssue.approx_decision_date
  def approx_processed_in_vbms_decision_date
    rating_promulgation_date ? rating_promulgation_date.to_date : end_product_last_action_date
  end

  def calculate_and_set_description
    self.description ||= calculate_description
  end

  def calculate_description
    return decision_text if decision_text
    return nil unless associated_request_issue

    "#{disposition}: #{associated_request_issue.description}"
  end

  def veteran_file_number
    decision_review.veteran_file_number
  end

  def appeal?
    decision_review_type == Appeal.to_s
  end

  def prior_payee_code
    latest_ep = decision_review.veteran
      .find_latest_end_product_by_claimant(decision_review.claimant)

    latest_ep&.payee_code
  end

  def dta_payee_code
    decision_review.payee_code || prior_payee_code || decision_review.claimant&.bgs_payee_code
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
    fail AppealDTAPayeeCodeError, decision_review.id unless dta_payee_code

    sc.create_claimant!(
      participant_id: decision_review.claimant_participant_id,
      payee_code: dta_payee_code,
      type: decision_review.claimant.type
    )

    sc
  rescue AppealDTAPayeeCodeError
    # mark SC as failed
    sc.update_error!("No payee code")
    decision_review.update_error!("DTA SC creation failed")
    raise
  end
end
