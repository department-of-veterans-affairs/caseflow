class SupplementalClaim < AmaReview
  validates :receipt_date, presence: { message: "blank" }, if: :saving_review

  END_PRODUCT_MODIFIERS = %w[040 041 042 043 044 045 046 047 048 049].freeze

  private

  # TODO: Update with real code and modifier data
  def end_product_code
    "040SCR"
  end

  def valid_modifiers
    END_PRODUCT_MODIFIERS
  end
end
