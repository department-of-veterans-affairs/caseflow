class EndProductEstablishment
  include ActiveModel::Model

  attr_accessor :veteran, :reference_id, :claim_date, :code, :valid_modifiers, :station, :cached_status

  class InvalidEndProductError < StandardError; end

  def perform!
    fail InvalidEndProductError unless end_product_to_establish.valid?

    establish_claim_in_vbms(end_product_to_establish).tap do |result|
      self.reference_id = result.claim_id
    end
  rescue VBMS::HTTPError => error
    raise Caseflow::Error::EstablishClaimFailedInVBMS.from_vbms_error(error)
  end

  def description
    reference_id && end_product_to_establish.description_with_routing
  end

  # Find an end product that has the traits of the end product that should be created.
  def preexisting_end_product
    @preexisting_end_product ||= veteran.end_products.find { |ep| end_product_to_establish.matches?(ep) }
  end

  def contentions
    end_product_to_establish.contentions
  end

  private

  def establish_claim_in_vbms(end_product)
    VBMSService.establish_claim!(
      claim_hash: end_product.to_vbms_hash,
      veteran_hash: veteran.to_vbms_hash
    )
  end

  def end_product_to_establish
    @end_product_to_establish ||= EndProduct.new(
      claim_id: reference_id,
      claim_date: claim_date,
      claim_type_code: code,
      modifier: valid_modifiers.first,
      suppress_acknowledgement_letter: false,
      gulf_war_registry: false,
      station_of_jurisdiction: station
    )
  end
end
