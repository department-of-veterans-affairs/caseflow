class HigherLevelReview < ClaimReview
  with_options if: :saving_review do
    validates :receipt_date, :benefit_type, presence: { message: "blank" }
    validates :informal_conference, :same_office, inclusion: { in: [true, false], message: "blank" }
  end

  END_PRODUCT_RATING_CODE = "030HLRR".freeze
  END_PRODUCT_NONRATING_CODE = "030HLRNR".freeze
  END_PRODUCT_MODIFIERS = %w[030 031 032 033 033 035 036 037 038 039].freeze
  DTA_ERRORS = ["DTA Error – PMRs", "DTA Error – Fed Recs", "DTA Error – Other Recs", "DTA Error – Exam/MO"].freeze

  def ui_hash
    {
      veteranFormName: veteran.name.formatted(:form),
      veteranName: veteran.name.formatted(:readable_short),
      veteranFileNumber: veteran_file_number,
      claimId: end_product_claim_id,
      receiptDate: receipt_date.to_formatted_s(:json_date),
      benefitType: benefit_type,
      issues: request_issues,
      sameOffice: same_office,
      informalConference: informal_conference
    }
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

  def end_product_claim_id
    rating_end_product_establishment && rating_end_product_establishment.reference_id
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

  def issue_code(rated)
    rated ? END_PRODUCT_RATING_CODE : END_PRODUCT_NONRATING_CODE
  end

  private

  def create_dta_supplemental_claim
    return if dta_issues.empty?
    dta_supplemental_claim.create_issues!(build_follow_up_dta_issues)
    dta_supplemental_claim.process_end_product_establishments!
  end

  def build_follow_up_dta_issues
    dta_issues.map do |dta_issue|
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

  def sync_dispositions(reference_id)
    super do |disposition, request_issue|
      if DTA_ERRORS.include?(disposition[:disposition])
        dta_issues << request_issue
      end
    end
  end

  def dta_issues
    @dta_issues ||= []
  end

  def dta_supplemental_claim
    @dta_supplemental_claim ||= SupplementalClaim.create!(
      veteran_file_number: veteran_file_number,
      receipt_date: Time.zone.now.to_date,
      is_dta_error: true
    )
  end

  def new_end_product_establishment(ep_code)
    end_product_establishments.build(
      veteran_file_number: veteran_file_number,
      claim_date: receipt_date,
      payee_code: payee_code,
      code: ep_code,
      claimant_participant_id: claimant_participant_id,
      station: "397" # AMC
    )
  end
end
