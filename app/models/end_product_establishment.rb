class EndProductEstablishment < ApplicationRecord
  class EstablishedEndProductNotFound < StandardError; end
  attr_accessor :valid_modifiers
  belongs_to :source, polymorphic: true

  class InvalidEndProductError < StandardError; end

  def perform!
    fail InvalidEndProductError unless end_product_to_establish.valid?

    establish_claim_in_vbms(end_product_to_establish).tap do |result|
      update!(reference_id: result.claim_id, established_at: Time.zone.now)
    end
  rescue VBMS::HTTPError => error
    raise Caseflow::Error::EstablishClaimFailedInVBMS.from_vbms_error(error)
  end

  # Fetch the resulting end product from the reference_id
  def result
    @result ||= fetch_result
  end

  def description
    reference_id && end_product_to_establish.description_with_routing
  end

  # Find an end product that has the traits of the end product that should be created.
  def preexisting_end_product
    @preexisting_end_product ||= veteran.end_products.find { |ep| end_product_to_establish.matches?(ep) }
  end

  delegate :contentions, to: :end_product_to_establish

  private

  def veteran
    @veteran ||= Veteran.find_or_create_by_file_number(veteran_file_number)
  end

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
      modifier: end_product_modifier,
      suppress_acknowledgement_letter: false,
      gulf_war_registry: false,
      station_of_jurisdiction: station
    )
  end

  def fetch_result
    return nil unless reference_id

    result = veteran.end_products.find do |end_product|
      end_product.claim_id == reference_id
    end

    fail EstablishedEndProductNotFound unless result
    result
  end

  def end_product_modifier
    return valid_modifiers.first if valid_modifiers.count == 1

    valid_modifiers.each do |modifier|
      if veteran.end_products.select { |ep| ep.modifier == modifier }.empty?
        return modifier
      end
    end
  end
end
