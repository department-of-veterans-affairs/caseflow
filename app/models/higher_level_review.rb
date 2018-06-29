class HigherLevelReview < AmaReview
  with_options if: :saving_review do
    validates :receipt_date, presence: { message: "blank" }
    validates :informal_conference, :same_office, inclusion: { in: [true, false], message: "blank" }
  end

  END_PRODUCT_MODIFIERS = %w[030 031 032 033 033 035 036 037 038 039].freeze

  private

  # TODO: Update with real code and modifier data
  def end_product_code
    "030HLRR"
  end

  def valid_modifiers
    END_PRODUCT_MODIFIERS
  end
end
