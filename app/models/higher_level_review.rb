class HigherLevelReview < AmaReview
  with_options if: :saving_review do
    validates :receipt_date, presence: { message: "blank" }
    validates :informal_conference, :same_office, inclusion: { in: [true, false], message: "blank" }
  end

  END_PRODUCT_MODIFIERS = %w[030 031 032 033 033 035 036 037 038 039].freeze

  def end_product_description
    end_product_establishment.description
  end

  def end_product_base_modifier
    # This is for EPs not yet created or that failed to create
    end_product_establishment.valid_modifiers.first
  end

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

  def establish_end_product!
    end_product_establishment.perform!

    update!(
      end_product_reference_id: end_product_establishment.reference_id,
      established_at: Time.zone.now
    )
  end

  private

  def end_product_establishment
    @end_product_establishment ||= EndProductEstablishment.new(
      veteran_file_number: veteran_file_number,
      reference_id: end_product_reference_id,
      claim_date: receipt_date,
      code: "030HLRR",
      valid_modifiers: END_PRODUCT_MODIFIERS,
      claimant_participant_id: claimant_participant_id,
      source: self,
      station: "397" # AMC
    )
  end
end
