class SupplementalClaim < ClaimReview
  validates :receipt_date, presence: { message: "blank" }, if: :saving_review

  END_PRODUCT_RATING_CODE = "040SCR".freeze
  END_PRODUCT_NONRATING_CODE = "040SCNR".freeze
  END_PRODUCT_MODIFIERS = %w[040 041 042 043 044 045 046 047 048 049].freeze

  def ui_hash
    {
      veteranFormName: veteran.name.formatted(:form),
      veteranName: veteran.name.formatted(:readable_short),
      veteranFileNumber: veteran_file_number,
      claimId: end_product_claim_id,
      receiptDate: receipt_date && receipt_date.to_formatted_s(:json_date),
      issues: request_issues
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

  def valid_modifiers
    END_PRODUCT_MODIFIERS
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

  private

  def issue_code(rated)
    rated ? END_PRODUCT_RATING_CODE : END_PRODUCT_NONRATING_CODE
  end
end
