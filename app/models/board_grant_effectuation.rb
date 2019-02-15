# BoardGrantEffectuation represents the work item of updating records in response to a granted issue on a Board appeal.
# Some are represented as contentions on an EP in VBMS. Others are tracked via Caseflow tasks.

class BoardGrantEffectuation < ApplicationRecord
  include HasBusinessLine
  include Asyncable

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

  delegate :contention_text, to: :granted_decision_issue
  delegate :veteran, to: :appeal

  class << self
    # We don't need to retry these as frequently
    def processing_retry_interval_hours
      12
    end

    def submitted_at_column
      :decision_sync_submitted_at
    end

    def attempted_at_column
      :decision_sync_attempted_at
    end

    def processed_at_column
      :decision_sync_processed_at
    end

    def error_column
      :decision_sync_error
    end
  end

  def sync_decision_issues!
    return if processed?

    attempted!
    return unless associated_rating

    update_from_matching_rating_issue!
    clear_error!
    processed!
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
      promulgation_date: matching_rating_issue.promulgation_date,
      profile_date: matching_rating_issue.profile_date,
      decision_text: matching_rating_issue.decision_text,
      rating_issue_reference_id: matching_rating_issue.reference_id
    )
  end

  def benefit_type
    granted_decision_issue.benefit_type
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
      payee_code: EndProduct::DEFAULT_PAYEE_CODE,
      code: end_product_code,
      station: end_product_station,
      benefit_type_code: veteran.benefit_type_code,
      user: User.system_user
    )
  end

  def end_product_code
    return unless processed_in_vbms?

    issue_code_type = granted_decision_issue.rating? ? :rating : :nonrating
    issue_code_type = "pension_#{issue_code_type}".to_sym if benefit_type == "pension"
    END_PRODUCT_CODES[issue_code_type]
  end

  def end_product_station
    "397" # ARC
  end
end
