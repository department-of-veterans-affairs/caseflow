class HigherLevelReview < ClaimReview
  with_options if: :saving_review do
    validates :informal_conference, :same_office, inclusion: { in: [true, false], message: "blank" }
  end

  END_PRODUCT_RATING_CODE = "030HLRR".freeze
  END_PRODUCT_NONRATING_CODE = "030HLRNR".freeze
  END_PRODUCT_MODIFIERS = %w[030 031 032 033 033 035 036 037 038 039].freeze

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

  def rating_end_product_establishment
    @rating_end_product_establishment ||= end_product_establishments.find_by(code: END_PRODUCT_RATING_CODE)
  end

  def end_product_description
    rating_end_product_establishment && rating_end_product_establishment.description
  end

  def end_product_base_modifier
    valid_modifiers.first
  end

  def special_issues
    return [] unless same_office
    [{ code: "SSR", narrative: "Same Station Review" }]
  end

  def valid_modifiers
    END_PRODUCT_MODIFIERS
  end

  def on_sync(end_product_establishment)
    super { create_dta_supplemental_claim }
  end

  def issue_code(rating: true)
    rating ? END_PRODUCT_RATING_CODE : END_PRODUCT_NONRATING_CODE
  end

  private

  def informal_conference?
    informal_conference
  end

  def create_dta_supplemental_claim
    return if dta_issues_needing_follow_up.empty?

    dta_supplemental_claim.create_issues!(build_follow_up_dta_issues)

    if run_async?
      ClaimReviewProcessJob.perform_later(dta_supplemental_claim)
    else
      ClaimReviewProcessJob.perform_now(dta_supplemental_claim)
    end
  end

  def build_follow_up_dta_issues
    dta_issues_needing_follow_up.map do |dta_issue|
      # do not copy over end product establishment id,
      # review request, removed_at, disposition, and contentions
      RequestIssue.new(
        review_request: dta_supplemental_claim,
        parent_request_issue_id: dta_issue.id,
        rating_issue_reference_id: dta_issue.rating_issue_reference_id,
        rating_issue_profile_date: dta_issue.rating_issue_profile_date,
        description: dta_issue.description,
        issue_category: dta_issue.issue_category,
        decision_date: dta_issue.decision_date
      )
    end
  end

  def dta_issues_needing_follow_up
    @dta_issues_needing_follow_up ||= request_issues.no_follow_up_issues.where(disposition: DTA_ERRORS)
  end

  def dta_supplemental_claim
    @dta_supplemental_claim ||= SupplementalClaim.create!(
      veteran_file_number: veteran_file_number,
      receipt_date: Time.zone.now.to_date,
      is_dta_error: true,
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
