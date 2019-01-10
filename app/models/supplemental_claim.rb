class SupplementalClaim < ClaimReview
  END_PRODUCT_CODES = {
    rating: "040SCR",
    nonrating: "040SCNR",
    pension_rating: "040SCRPMC",
    pension_nonrating: "040SCNRPMC",
    dta_rating: "040HDER",
    dta_nonrating: "040HDENR",
    dta_pension_rating: "040HDERPMC",
    dta_pension_nonrating: "040HDENRPMC",
    dta_board: "040BDE",
    imo_dta_board: "040BDEIMO",
    pension_dta_board: "040BDEPMC",
    pension_imo_dta_board: "040BDEIMOPMC"
  }.freeze

  END_PRODUCT_MODIFIERS = %w[040 041 042 043 044 045 046 047 048 049].freeze

  belongs_to :decision_review_remanded, polymorphic: true

  def ui_hash
    super.merge(
      formType: "supplemental_claim",
      isDtaError: decision_review_remanded?
    )
  end

  def issue_code(rating: true)
    if decision_review_remanded? && decision_review_remanded.is_a?(Appeal)
      issue_code_type = :board
    else
      issue_code_type = rating ? :rating : :nonrating
    end
    
      issue_code_type = "pension_#{issue_code_type}".to_sym if benefit_type == "pension"
      issue_code_type = "dta_#{issue_code_type}".to_sym if decision_review_remanded?
      END_PRODUCT_CODES[issue_code_type]
  end

  def start_processing_job!
    if run_async?
      DecisionReviewProcessJob.perform_later(self)
    else
      DecisionReviewProcessJob.perform_now(self)
    end
  end

  def create_remand_issues!
    create_issues!(build_request_issues_from_remand)
  end

  private

  def end_product_created_by
    decision_review_remanded? ? User.system_user : intake_processed_by
  end

  def end_product_station
    decision_review_remanded? ? "397" : super
  end

  def new_end_product_establishment(ep_code)
    end_product_establishments.build(
      veteran_file_number: veteran_file_number,
      claim_date: receipt_date,
      payee_code: payee_code,
      code: ep_code,
      claimant_participant_id: claimant_participant_id,
      station: end_product_station,
      benefit_type_code: veteran.benefit_type_code,
      user: end_product_created_by
    )
  end

  def build_request_issues_from_remand
    remanded_decision_issues_needing_request_issues.map do |remand_decision_issue|
      RequestIssue.new(
        review_request: self,
        contested_decision_issue_id: remand_decision_issue.id,
        contested_rating_issue_reference_id: remand_decision_issue.rating_issue_reference_id,
        contested_rating_issue_profile_date: remand_decision_issue.profile_date,
        contested_issue_description: remand_decision_issue.description,
        issue_category: remand_decision_issue.issue_category,
        benefit_type: benefit_type,
        decision_date: remand_decision_issue.approx_decision_date
      )
    end
  end

  def remanded_decision_issues_needing_request_issues
    remanded_decision_issues.select do |decision_issue|
      !decision_issue.contesting_request_issue
    end
  end

  def remanded_decision_issues
    decision_review_remanded.decision_issues.remanded.where(benefit_type: benefit_type)
  end
end
