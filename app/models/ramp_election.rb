class RampElection < RampReview
  class InvalidEndProductError < StandardError; end
  class EstablishedEndProductNotFound < StandardError; end

  attr_reader :saving_receipt

  has_many :intakes, as: :detail, class_name: "RampElectionIntake"

  RESPOND_BY_TIME = 60.days.freeze

  validate :validate_receipt_date

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

  def self.completed
    where.not(end_product_reference_id: nil)
  end

  def established_end_product
    @established_end_product ||= fetch_established_end_product
  end

  private

  def fetch_established_end_product
    return nil unless end_product_reference_id

    result = Veteran.new(file_number: veteran_file_number).end_products.find do |end_product|
      end_product.claim_id == end_product_reference_id
    end

    fail EstablishedEndProductNotFound unless result
    result
  end

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
