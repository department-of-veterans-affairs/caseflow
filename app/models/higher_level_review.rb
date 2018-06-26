class HigherLevelReview < AmaReview
  with_options if: :saving_review do
    validates :receipt_date, presence: { message: "blank" }
    validates :informal_conference, :same_office, inclusion: { in: [true, false], message: "blank" }
  end

  def self.veteran_name_by_claim_id(claim_id:)
    intake_by_claim_id = self.find_by(end_product_reference_id: claim_id
    )
    intake_by_claim_id && Veteran.find_or_create_by_file_number(intake_by_claim_id.veteran_file_number).name
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
