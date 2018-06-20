class SupplementalClaim < AmaReview
  validates :receipt_date, presence: { message: "blank" }, if: :saving_review

  private

  # TODO: Update with real code and modifier data
  def end_product_code
    "040SCR"
  end

  END_PRODUCT_MODIFIERS = %w[040 041 042 043 044 045 046 047 048 049].freeze

  def end_product_modifier
    END_PRODUCT_MODIFIERS.each do |modifier|
      if veteran.end_products.select { |ep| ep.modifier == modifier }.empty?
        return modifier
      end
    end
  end
end
