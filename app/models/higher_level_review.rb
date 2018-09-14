class HigherLevelReview < ClaimReview
  with_options if: :saving_review do
    validates :receipt_date, presence: { message: "blank" }
    validates :informal_conference, :same_office, inclusion: { in: [true, false], message: "blank" }
  end

  END_PRODUCT_RATING_CODE = "030HLRR".freeze
  END_PRODUCT_NONRATING_CODE = "030HLRNR".freeze
  END_PRODUCT_MODIFIERS = %w[030 031 032 033 033 035 036 037 038 039].freeze
  DTA_ERRORS = ["DTA Error – PMRs", "DTA Error – Fed Recs", "DTA Error – Other Recs", "DTA Error – Exam/MO"].freeze
  DTA_SUPPLEMENTAL_CLAIM_CODES = { rating: "040HDENR", nonrating: "040HDER"}

  def ui_hash
    {
      veteranFormName: veteran.name.formatted(:form),
      veteranName: veteran.name.formatted(:readable_short),
      veteranFileNumber: veteran_file_number,
      claimId: end_product_claim_id,
      receiptDate: receipt_date.to_formatted_s(:json_date),
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

  def dta_errors
    DTA_ERRORS
  end

  def create_duty_to_assist_supplemental_claim_if_needed(end_product_establishment)
    return if dta_issues.empty?
    rating_code_type = dta_issues.first.rated? ? :rating : :nonrating
    sc = create_supplemental_claim
    ep = sc.new_end_product_establishment(DTA_SUPPLEMENTAL_CLAIM_CODES[rating_code_type])
    ep.perform!

    # create duplicate dta issues that link to original
    new_issues = dta_issues.map do |dta_issue|
      new_issue = dta_issue.dup
      new_issue.assign_attributes(
        parent_request_issue_id: dta_issue.id,
        review_request_id: ep.id,
        review_request_type: ep.source_type
      )
      new_issue
    end
    create_issues!(new_issues)
  end

  private

  def create_supplemental_claim
    SupplementalClaim.create!(
      veteran_file_number: veteran_file_number,
      receipt_date: Time.zone.now.to_date
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

  def issue_code(rated)
    rated ? END_PRODUCT_RATING_CODE : END_PRODUCT_NONRATING_CODE
  end
end
