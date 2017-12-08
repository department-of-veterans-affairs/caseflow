class RampElection < ActiveRecord::Base
  class InvalidEndProductError < StandardError; end

  attr_reader :saving_receipt

  has_many :intakes, as: :detail, class_name: "RampElectionIntake"

  enum option_selected: {
    supplemental_claim: "supplemental_claim",
    higher_level_review: "higher_level_review",
    higher_level_review_with_hearing: "higher_level_review_with_hearing"
  }

  END_PRODUCT_DATA_BY_OPTION = {
    "supplemental_claim" => { code: "683SCRRRAMP", modifier: "683" },
    "higher_level_review" => { code: "682HLRRRAMP", modifier: "682" },
    "higher_level_review_with_hearing" => { code: "682HLRRRAMP", modifier: "682" }
  }.freeze

  END_PRODUCT_STATION = "397".freeze # AMC

  RESPOND_BY_TIME = 60.days.freeze

  validates :receipt_date, :option_selected, presence: { message: "blank" }, if: :saving_receipt
  validate :validate_receipt_date

  def start_saving_receipt
    @saving_receipt = true
  end

  def create_end_product!
    fail InvalidEndProductError unless end_product.valid?

    establish_claim_in_vbms(end_product).tap do |result|
      update!(end_product_reference_id: result.claim_id)
    end

  rescue VBMS::HTTPError => error
    raise Caseflow::Error::EstablishClaimFailedInVBMS.from_vbms_error(error)
  end

  def successfully_received?
    intakes.where(completion_status: "success").any?
  end

  def end_product_description
    end_product_reference_id && end_product.description_with_routing
  end

  # RAMP letters request that Veterans respond within 60 days; elections will
  # be accepted after this point, however, so this "due date" is soft.
  def due_date
    notice_date + RESPOND_BY_TIME if notice_date
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

  def validate_receipt_date
    return unless notice_date && receipt_date

    if notice_date > receipt_date
      errors.add(:receipt_date, "before_notice_date")
    elsif Time.zone.today < receipt_date
      errors.add(:receipt_date, "in_future")
    end
  end
end
