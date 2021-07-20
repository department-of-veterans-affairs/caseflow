# frozen_string_literal: true

# BoardGrantEffectuation represents the work item of updating records in response to a granted issue on a Board appeal.
# Some are represented as contentions on an EP in VBMS. Others are tracked via Caseflow tasks.

class BoardGrantEffectuation < CaseflowRecord
  include HasBusinessLine
  include Asyncable
  include DecisionSyncable

  belongs_to :appeal
  belongs_to :granted_decision_issue, class_name: "DecisionIssue"
  belongs_to :decision_document
  belongs_to :end_product_establishment

  validates :granted_decision_issue, presence: true
  before_save :hydrate_from_granted_decision_issue, on: :create

  END_PRODUCT_CODES = {
    rating: "030BGR",
    nonrating: "030BGRNR",
    pension_rating: "030BGRPMC",
    pension_nonrating: "030BGNRPMC"
  }.freeze

  END_PRODUCT_CORRECTION_CODES = {
    rating: "930AMABGRC",
    nonrating: "930AMABGNRC",
    pension_rating: "930ABGRCPMC",
    pension_nonrating: "930ABGNRCPMC"
  }.freeze

  delegate :contention_text, to: :granted_decision_issue
  delegate :veteran, :claimant, to: :appeal

  # don't need to try as frequently as default 3 hours
  DEFAULT_REQUIRES_PROCESSING_RETRY_WINDOW_HOURS = 12

  def sync_decision_issues!
    return if processed?

    attempted!
    if granted_decision_issue.rating?
      return unless associated_rating

      update_from_matching_rating_issue!
    end
    clear_error!
    processed!
  end

  def contention_type
    Constants.CONTENTION_TYPES.default
  end

  private

  def associated_rating
    end_product_establishment.associated_rating
  end

  def matching_rating_issue
    return unless associated_rating

    @matching_rating_issue || associated_rating.issues.find do |rating_issue|
      rating_issue.decides_contention?(contention_reference_id: contention_reference_id)
    end
  end

  def update_from_matching_rating_issue!
    return unless matching_rating_issue

    granted_decision_issue.update!(
      rating_promulgation_date: matching_rating_issue.promulgation_date,
      rating_profile_date: matching_rating_issue.profile_date,
      decision_text: matching_rating_issue.decision_text,
      rating_issue_reference_id: matching_rating_issue.reference_id,
      subject_text: matching_rating_issue.subject_text,
      percent_number: matching_rating_issue.percent_number
    )
  end

  def benefit_type
    granted_decision_issue.benefit_type
  end

  # This method is not implemented yet
  def correction?
    false
  end

  def hydrate_from_granted_decision_issue
    assign_attributes(
      appeal: granted_decision_issue.decision_review,
      decision_document: granted_decision_issue.decision_review.decision_document
    )

    if processed_in_vbms?
      self.end_product_establishment ||= find_or_build_end_product_establishment
    else
      find_or_build_effectuation_task
    end
  end

  def find_or_build_effectuation_task
    find_matching_effectuation_task || create_effectuation_task!
  end

  def find_matching_effectuation_task
    BoardGrantEffectuationTask.find_by(
      appeal: appeal,
      assigned_to: business_line
    )
  end

  def create_effectuation_task!
    BoardGrantEffectuationTask.create!(
      appeal: appeal,
      assigned_at: Time.zone.now,
      assigned_to: business_line
    )
  end

  def find_or_build_end_product_establishment
    find_matching_end_product_establishment || build_end_product_establishment
  end

  def find_matching_end_product_establishment
    EndProductEstablishment.find_by(
      source: decision_document,
      code: end_product_code,
      established_at: nil
    )
  end

  def build_end_product_establishment
    EndProductEstablishment.create!(
      source: decision_document,
      veteran_file_number: veteran.file_number,
      claim_date: decision_document.decision_date,
      claimant_participant_id: claimant_participant_id,
      payee_code: claimant_payee_code,
      code: end_product_code,
      station: end_product_station,
      benefit_type_code: veteran.benefit_type_code,
      user: User.system_user
    )
  end

  def claimant_participant_id
    # Board Grant EPs need to be created with the veteran's participant ID when claimant is an Attorney, per BVA
    claimant.is_a?(AttorneyClaimant) ? veteran&.participant_id : claimant&.participant_id
  end

  def claimant_payee_code
    if claimant&.payee_code.present?
      claimant.payee_code
    elsif appeal&.veteran_is_not_claimant
      veteran&.relationship_with_participant_id(claimant.participant_id)&.default_payee_code
    end || EndProduct::DEFAULT_PAYEE_CODE
  end

  def end_product_code
    return unless processed_in_vbms?

    correction? ? END_PRODUCT_CORRECTION_CODES[issue_code_type] : END_PRODUCT_CODES[issue_code_type]
  end

  def issue_code_type
    @issue_code_type ||= begin
      key = granted_decision_issue.rating? ? :rating : :nonrating
      key = "pension_#{key}".to_sym if benefit_type == "pension"
      key
    end
  end

  def end_product_station
    "397" # ARC
  end
end
