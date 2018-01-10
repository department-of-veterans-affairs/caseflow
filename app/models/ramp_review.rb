class RampReview < ActiveRecord::Base
  class EstablishedEndProductNotFound < StandardError; end
  class InvalidEndProductError < StandardError; end

  self.abstract_class = true

  attr_reader :saving_review

  enum option_selected: {
    supplemental_claim: "supplemental_claim",
    higher_level_review: "higher_level_review",
    higher_level_review_with_hearing: "higher_level_review_with_hearing",
    appeal: "appeal"
  }

  has_many :issues, as: :review, class_name: "RampIssue"

  HIGHER_LEVEL_REVIEW_OPTIONS = %w[higher_level_review higher_level_review_with_hearing].freeze

  END_PRODUCT_DATA_BY_OPTION = {
    "supplemental_claim" => { code: "683SCRRRAMP", modifier: "683" },
    "higher_level_review" => { code: "682HLRRRAMP", modifier: "682" },
    "higher_level_review_with_hearing" => { code: "682HLRRRAMP", modifier: "682" }
  }.freeze

  END_PRODUCT_STATION = "397".freeze # AMC

  validates :receipt_date, :option_selected, presence: { message: "blank" }, if: :saving_review

  # Allows us to enable certain validations only when saving the review
  def start_review!
    @saving_review = true
  end

  def higher_level_review?
    HIGHER_LEVEL_REVIEW_OPTIONS.include?(option_selected)
  end

  def create_end_product!
    fail InvalidEndProductError unless end_product.valid?

    establish_claim_in_vbms(end_product).tap do |result|
      update!(end_product_reference_id: result.claim_id)
    end
  rescue VBMS::HTTPError => error
    raise Caseflow::Error::EstablishClaimFailedInVBMS.from_vbms_error(error)
  end

  def end_product_description
    end_product_reference_id && end_product.description_with_routing
  end

  private

  def end_product
    @end_product ||= EndProduct.new(
      claim_id: end_product_reference_id,
      claim_date: receipt_date,
      claim_type_code: end_product_data_hash[:code],
      modifier: end_product_data_hash[:modifier],
      suppress_acknowledgement_letter: false,
      gulf_war_registry: false,
      station_of_jurisdiction: END_PRODUCT_STATION
    )
  end

  def end_product_data_hash
    END_PRODUCT_DATA_BY_OPTION[option_selected] || {}
  end

  def veteran
    @veteran ||= Veteran.new(file_number: veteran_file_number).load_bgs_record!
  end

  def establish_claim_in_vbms(end_product)
    VBMSService.establish_claim!(
      claim_hash: end_product.to_vbms_hash,
      veteran_hash: veteran.to_vbms_hash
    )
  end

  def validate_receipt_date_not_in_future
    errors.add(:receipt_date, "in_future") if Time.zone.today < receipt_date
  end
end
