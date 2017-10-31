class RampElection < ActiveRecord::Base
  attr_reader :saving_receipt

  has_many :ramp_intakes, as: :detail

  enum option_selected: {
    supplemental_claim: "supplemental_claim",
    higher_level_review: "higher_level_review",
    higher_level_review_with_hearing: "higher_level_review_with_hearing"
  }

  validates :receipt_date, :option_selected, presence: { message: "blank" }, if: :saving_receipt
  validate :validate_receipt_date

  def start_saving_receipt
    @saving_receipt = true
  end

<<<<<<< HEAD
  def create_end_product!(end_product_params)
    end_product = EndProduct.new(
      claim_date: Time.zone.now,
      claim_type_code: hash[:end_product_code],
      modifier: hash[:end_product_modifier],
      suppress_acknowledgement_letter: hash[:suppress_acknowledgement_letter],
      gulf_war_registry: hash[:gulf_war_registry],
      station_of_jurisdiction: hash[:station_of_jurisdiction]
    )

    fail InvalidEndProductError unless end_product.valid?


    establish_claim_in_vbms(end_product).tap do |result|
      ## SAVE THE EP ID
    end

  rescue VBMS::HTTPError => error
    raise parse_vbms_error(error)
=======
  def successfully_received?
    ramp_intakes.where(completion_status: "success").any?
>>>>>>> master
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
