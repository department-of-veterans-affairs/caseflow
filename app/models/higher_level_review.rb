class HigherLevelReview < ClaimReview
  with_options if: :saving_review do
    validates :informal_conference, :same_office, inclusion: { in: [true, false], message: "blank" }
  end

  END_PRODUCT_MODIFIERS = %w[030 031 032 033 034 035 036 037 038 039].freeze

  # NOTE: These are the string identifiers for the DTA error dispositions returned from VBMS.
  # The characters an encoding is precise so don't change these unless you know they match VBMS values.
  DTA_ERROR_PMR = "DTA Error - PMRs".freeze
  DTA_ERROR_FED_RECS = "DTA Error - Fed Recs".freeze
  DTA_ERROR_OTHER_RECS = "DTA Error - Other Recs".freeze
  DTA_ERROR_EXAM_MO = "DTA Error - Exam/MO".freeze
  DTA_ERRORS = [DTA_ERROR_PMR, DTA_ERROR_FED_RECS, DTA_ERROR_OTHER_RECS, DTA_ERROR_EXAM_MO].freeze

  def self.review_title
    Constants.INTAKE_FORM_NAMES_SHORT.higher_level_review
  end

  def ui_hash
    super.merge(
      formType: "higher_level_review",
      sameOffice: same_office,
      informalConference: informal_conference
    )
  end

  def on_decision_issues_sync_processed(_end_product_establishment)
    create_dta_supplemental_claim
  end

## needed for appeal status api
    
  def review_status_id
    "HLR#{id}"
  end

  def linked_review_ids
    Array.wrap(review_status_id)
  end

  def incomplete
    false
  end

  def active?
    end_product_establishments.any? { |ep| ep.status_active?(sync: false) }
  end

  def description
    # need to impelement
  end

  def aoj
    # neet to implement. add logic to return proper enum: - vba, vha, nca, other 
  end

  def program
    case benefit_type
    when "voc_rehab"
      "vre"
    when "vha"
      "medical"
    when "nca"
      "burial"
    else
      return benefit_type
    end
  end

  def status_hash
    # need to implement. returns the details object for the status
  end

  def alerts
    # need to implement. add logic to return alert enum
  end

  def issues
    # need to implement. get request and corresponding rating issue
    []
  end

  def events
    # need to implement. hlr_request, hlr_decision, hlr_dta_error, or hlr_other_close
  end

  private

  def create_dta_supplemental_claim
    return if dta_issues_needing_follow_up.empty?

    dta_supplemental_claim.create_issues!(build_follow_up_dta_issues)
    dta_supplemental_claim.create_decision_review_task_if_required!
    dta_supplemental_claim.start_processing_job!
  end

  def dta_issues_needing_follow_up
    @dta_issues_needing_follow_up ||= decision_issues.where(disposition: DTA_ERRORS)
  end

  def dta_supplemental_claim
    unless dta_issues_needing_follow_up.first.approx_decision_date
      fail "approx_decision_date is required to create a DTA Supplemental Claim"
    end

    @dta_supplemental_claim ||= SupplementalClaim.create!(
      veteran_file_number: veteran_file_number,
      receipt_date: dta_issues_needing_follow_up.first.approx_decision_date,
      decision_review_remanded: self,
      benefit_type: benefit_type,
      legacy_opt_in_approved: legacy_opt_in_approved,
      veteran_is_not_claimant: veteran_is_not_claimant
    ).tap do |sc|
      sc.create_claimants!(
        participant_id: claimant_participant_id,
        payee_code: payee_code
      )
    end
  end

  def build_follow_up_dta_issues
    dta_issues_needing_follow_up.map do |dta_decision_issue|
      # do not copy over end product establishment id,
      # review request, removed_at, disposition, and contentions
      RequestIssue.new(
        review_request: dta_supplemental_claim,
        contested_decision_issue_id: dta_decision_issue.id,
        # parent_request_issue_id: dta_issue.id, delete this from table
        rating_issue_reference_id: dta_decision_issue.rating_issue_reference_id,
        rating_issue_profile_date: dta_decision_issue.profile_date.to_s,
        contested_rating_issue_reference_id: dta_decision_issue.rating_issue_reference_id,
        contested_rating_issue_profile_date: dta_decision_issue.profile_date,
        contested_issue_description: dta_decision_issue.description,
        issue_category: dta_decision_issue.issue_category,
        benefit_type: dta_decision_issue.benefit_type,
        decision_date: dta_decision_issue.approx_decision_date
      )
    end
  end

  def informal_conference?
    informal_conference
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
      user: intake_processed_by
    )
  end
end
