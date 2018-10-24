class SupplementalClaim < ClaimReview
  with_options if: :saving_review do
    validates :receipt_date, :benefit_type, presence: { message: "blank" }
    validates :legacy_opt_in_approved, inclusion: { in: [true, false], message: "blank" }
  end

  END_PRODUCT_CODES = {
    rating: "040SCR",
    nonrating: "040SCNR",
    dta_rating: "040HDER",
    dta_nonrating: "040HDENR"
  }.freeze

  END_PRODUCT_MODIFIERS = %w[040 041 042 043 044 045 046 047 048 049].freeze

  def ui_hash(ama_enabled)
    super.merge(
      formType: "supplemental_claim"
    )
  end

  def rating_end_product_establishment
    @rating_end_product_establishment ||= end_product_establishments.find_by(code: END_PRODUCT_CODES[:rating])
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

  def valid_modifiers
    END_PRODUCT_MODIFIERS
  end

  def issue_code(rated)
    issue_code_type = rated ? :rating : :nonrating
    if is_dta_error
      issue_code_type = rated ? :dta_rating : :dta_nonrating
    end
    END_PRODUCT_CODES[issue_code_type]
  end

  private

  def new_end_product_establishment(ep_code)
    end_product_establishments.build(
      veteran_file_number: veteran_file_number,
      claim_date: receipt_date,
      payee_code: payee_code,
      code: ep_code,
      claimant_participant_id: claimant_participant_id,
      station: end_product_station,
      benefit_type_code: veteran.benefit_type_code
    )
  end
end
