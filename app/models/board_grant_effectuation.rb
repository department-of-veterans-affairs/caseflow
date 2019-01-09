# BoardGrantEffectuation represents the work item of updating records in response to a granted issue on a Board appeal.
# Some are represented as contentions on an EP in VBMS. Others are tracked via Caseflow tasks.

class BoardGrantEffectuation < ApplicationRecord
  belongs_to :appeal
  belongs_to :granted_decision_issue, class_name: "DecisionIssue"
  belongs_to :decision_document
  belongs_to :end_product_establishment

  validates :granted_decision_issue, presence: true
  before_save :hydrate_from_granted_decision_issue, on: :create

  END_PRODUCT_CODES = {
    rating: "030BGR",
    nonrating: "030BGNR",
    pension_rating: "030BGRPMC",
    pension_nonrating: "030BGNRPMC"
  }.freeze

  def contention_text
    granted_decision_issue.description
  end

  private

  def effectuated_in_vbms?
    %w[compensation pension].include?(granted_decision_issue.benefit_type)
  end

  def hydrate_from_granted_decision_issue
    assign_attributes(
      appeal: granted_decision_issue.decision_review,
      decision_document: granted_decision_issue.decision_review.decision_document
    )

    if effectuated_in_vbms?
      self.end_product_establishment = find_or_build_end_product_establishment
    end
  end

  def find_or_build_end_product_establishment
    find_matching_end_product_establishment || build_end_product_establishment
  end

  def find_matching_end_product_establishment
    EndProductEstablishment.find_by(
      source: decision_document,
      code: ep_code,
      established_at: nil
    )
  end

  def build_end_product_establishment
    EndProductEstablishment.create!(
      source: decision_document,
      veteran_file_number: veteran.file_number,
      claim_date: decision_document.decision_date,
      payee_code: "00",
      code: ep_code,
      station: end_product_station,
      benefit_type_code: veteran.benefit_type_code,
      user: User.system_user
    )
  end

  def veteran
    appeal.veteran
  end

  def ep_code
    return unless effectuated_in_vbms?

    issue_code_type = granted_decision_issue.rating? ? :rating : :nonrating
    issue_code_type = "pension_#{issue_code_type}".to_sym if granted_decision_issue.benefit_type == "pension"
    END_PRODUCT_CODES[issue_code_type]
  end

  def end_product_station
    "397" # ARC
  end
end
