class SupplementalClaim < ClaimReview
  END_PRODUCT_CODES = {
    rating: "040SCR",
    nonrating: "040SCNR",
    dta_rating: "040HDER",
    dta_nonrating: "040HDENR"
  }.freeze

  END_PRODUCT_MODIFIERS = %w[040 041 042 043 044 045 046 047 048 049].freeze

  def ui_hash
    super.merge(
      formType: "supplemental_claim",
      isDtaError: is_dta_error
    )
  end

  def rating_end_product_establishment
    @rating_end_product_establishment ||= end_product_establishments.find_by(code: END_PRODUCT_CODES[:rating])
  end

  def end_product_description
    rating_end_product_establishment&.description
  end

  def end_product_base_modifier
    valid_modifiers.first
  end

  def valid_modifiers
    END_PRODUCT_MODIFIERS
  end

  def issue_code(rating: true)
    issue_code_type = rating ? :rating : :nonrating
    if is_dta_error?
      issue_code_type = "dta_#{issue_code_type}".to_sym
    end
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
