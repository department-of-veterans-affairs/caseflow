class RampElection < ActiveRecord::Base
  attr_reader :saving_receipt

  has_many :ramp_intakes, as: :detail

  enum option_selected: {
    supplemental_claim: "supplemental_claim",
    higher_level_review: "higher_level_review",
    higher_level_review_with_hearing: "higher_level_review_with_hearing"
  }

  END_PRODUCT_DATA_BY_OPTION = {
    "supplemental_claim" => { code: "683SCRRRAMP", modifier: "683" },
    "higher_level_review" => { code: "682HLRRRAMP", modifier: "682" },
    "higher_level_review_with_hearing" => { code: "682HLRRRAMP", modifier: "682" }
  }

  validates :receipt_date, :option_selected, presence: { message: "blank" }, if: :saving_receipt
  validate :validate_receipt_date

  def start_saving_receipt
    @saving_receipt = true
  end

  def create_end_product!
    end_product = EndProduct.new(
      claim_date: receipt_date,
      claim_type_code: END_PRODUCT_DATA_BY_OPTION[option_selected][:code],
      modifier: END_PRODUCT_DATA_BY_OPTION[option_selected][:modifier],
      suppress_acknowledgement_letter: false,
      gulf_war_registry: false,
      station_of_jurisdiction: "397"
    )

    fail InvalidEndProductError unless end_product.valid?

    establish_claim_in_vbms(end_product).tap do |result|
      self.end_product_reference_id = result.claim_id
    end

  rescue VBMS::HTTPError => error
    raise Caseflow::Error::EstablishClaimFailedInVBMS.from_vbms_error(error)
  end

  def successfully_received?
    ramp_intakes.where(completion_status: "success").any?
  end

  private

  def establish_claim_in_vbms(end_product)
    VBMSService.establish_claim!(
      claim_hash: end_product.to_vbms_hash,
      veteran_hash: appeal.veteran.to_vbms_hash
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
