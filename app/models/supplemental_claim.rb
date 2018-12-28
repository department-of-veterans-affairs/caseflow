class SupplementalClaim < ClaimReview
  END_PRODUCT_CODES = {
    rating: "040SCR",
    nonrating: "040SCNR",
    pension_rating: "040SCRPMC",
    pension_nonrating: "040SCNRPMC",
    dta_rating: "040HDER",
    dta_nonrating: "040HDENR",
    pension_dta_rating: "040HDERPMC",
    pension_dta_nonrating: "040HDENRPMC"
  }.freeze

  END_PRODUCT_MODIFIERS = %w[040 041 042 043 044 045 046 047 048 049].freeze

  def ui_hash
    super.merge(
      formType: "supplemental_claim",
      isDtaError: is_dta_error
    )
  end

  def issue_code(rating: true)
    issue_code_type = rating ? :rating : :nonrating
    issue_code_type = "dta_#{issue_code_type}".to_sym if is_dta_error?
    issue_code_type = "pension_#{issue_code_type}".to_sym if benefit_type == "pension"
    END_PRODUCT_CODES[issue_code_type]
  end

  private

  def end_product_created_by
    is_dta_error? ? User.system_user : intake_processed_by
  end

  def end_product_station
    is_dta_error? ? "397" : super
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
end
