class HigherLevelReview < AmaReview
  with_options if: :saving_review do
    validates :receipt_date, presence: { message: "blank" }
    validates :informal_conference, :same_office, inclusion: { in: [true, false], message: "blank" }
  end

  END_PRODUCT_RATED_CODE = "030HLRR".freeze
  END_PRODUCT_NONRATED_CODE = "030HLRNR".freeze
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

  def create_contentions_in_vbms(rated: true)
    VBMSService.create_contentions!(
      veteran_file_number: veteran_file_number,
      claim_id: end_product_establishment.reference_id,
      contention_descriptions: issue_descriptions_to_create(rated: rated),
      special_issues: special_issues
    )
  end

  private

  def find_end_product_establishment(ep_code)
    EndProductEstablishment.find_by(source: self, code: ep_code)
  end

  def new_end_product_establishment(ep_code)
    EndProductEstablishment.new(
      veteran_file_number: veteran_file_number,
      reference_id: end_product_reference_id,
      claim_date: receipt_date,
      code: ep_code,
      valid_modifiers: END_PRODUCT_MODIFIERS,
      source: self,
      station: "397" # AMC
    )
  end

  def end_product_establishment(rated: true)
    ep_code = issue_code(rated)
    @end_product_establishments ||= {}
    @end_product_establishments[rated] ||=
      find_end_product_establishment(ep_code) || new_end_product_establishment(ep_code)
  end

  def issue_code(rated)
    rated ? END_PRODUCT_RATED_CODE : END_PRODUCT_NONRATED_CODE
  end
end
