class HigherLevelReview < AmaReview
  validate :validate_receipt_date

  with_options if: :saving_review do
    validates :receipt_date, presence: { message: "blank" }
    validates :informal_conference, :same_office, inclusion: { in: [true, false], message: "blank" }
  end

  private

  # TODO: Update with real code and modifier data
  def end_product_code
    "030HLRR"
  end

  END_PRODUCT_MODIFIERS = %w[030 031 032 033 033 035 036 037 038 039].freeze

  def end_product_modifier
    END_PRODUCT_MODIFIERS.each do |modifier|
      if veteran.end_products.select { |ep| ep.modifier == modifier }.empty?
        return modifier
      end
    end
  end
end
