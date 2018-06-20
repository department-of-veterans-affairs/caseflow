class SupplementalClaim < AmaReview
  validates :receipt_date, presence: { message: "blank" }, if: :saving_review

  private

  def end_product_code
    "040SCR"
  end

  def end_product_modifiers
    %w[040 041 042 043 044 045 046 047 048 049].freeze
  end
end
