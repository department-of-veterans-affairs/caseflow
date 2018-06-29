class HigherLevelReview < AmaReview
  with_options if: :saving_review do
    validates :receipt_date, presence: { message: "blank" }
    validates :informal_conference, :same_office, inclusion: { in: [true, false], message: "blank" }
  end

  END_PRODUCT_MODIFIERS = %w[030 031 032 033 033 035 036 037 038 039].freeze

  private

  def special_issues
    return [] unless same_office
    [{ code: "SSR", narrative: "Same Station Review" }]
  end

  def create_contentions_in_vbms
    VBMSService.create_contentions!(
      veteran_file_number: veteran_file_number,
      claim_id: end_product_reference_id,
      contention_descriptions: contention_descriptions_to_create,
      special_issues: special_issues
    )
  end

  def end_product_code
    "030HLRR"
  end

  def valid_modifiers
    END_PRODUCT_MODIFIERS
  end
end
