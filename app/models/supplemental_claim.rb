class SupplementalClaim < AmaReview
  validates :receipt_date, presence: { message: "blank" }, if: :saving_review

  END_PRODUCT_MODIFIERS = %w[040 041 042 043 044 045 046 047 048 049].freeze

  def end_product_description
    end_product_establishment.description
  end

  def end_product_base_modifier
    # This is for EPs not yet created or that failed to create
    end_product_establishment.valid_modifiers.first
  end

  private

  def find_end_product_establishment
    @preexisting_end_product_establishment ||= EndProductEstablishment.find_by(source: self)
  end

  def new_end_product_establishment
    @new_end_product_establishment ||= EndProductEstablishment.new(
      veteran_file_number: veteran_file_number,
      reference_id: end_product_reference_id,
      claim_date: receipt_date,
      code: "040SCR",
      payee_code: payee_code,
      valid_modifiers: END_PRODUCT_MODIFIERS,
      source: self,
      station: "397" # AMC
    )
  end

  def end_product_establishment
    find_end_product_establishment || new_end_product_establishment
  end
end
