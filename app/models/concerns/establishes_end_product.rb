module EstablishesEndProduct
  # Dependencies that are okay:
  # end_product_reference_id
  # receipt_date
  # end_product_code
  # end_product_modifier
  # end_product_station
  # veteran
  # established_at=

  extend ActiveSupport::Concern
  class EstablishedEndProductNotFound < StandardError; end
  class InvalidEndProductError < StandardError; end

  # TODO rename to establish_end_product
  def create_end_product!
    fail InvalidEndProductError unless end_product.valid?

    establish_claim_in_vbms(end_product).tap do |result|
      update!(
        end_product_reference_id: result.claim_id,
        established_at: Time.zone.now
      )
    end
  rescue VBMS::HTTPError => error
    raise Caseflow::Error::EstablishClaimFailedInVBMS.from_vbms_error(error)
  end

  def established?
    !!established_at
  end

  def established_end_product
    @established_end_product ||= fetch_established_end_product
  end

  private

  # TODO rename to end_product_to_establish
  def end_product
    @end_product ||= EndProduct.new(
      claim_id: end_product_reference_id,
      claim_date: receipt_date,
      claim_type_code: end_product_code,
      modifier: end_product_modifier,
      suppress_acknowledgement_letter: false,
      gulf_war_registry: false,
      station_of_jurisdiction: end_product_station
    )
  end

# TODO Remove load_bgs_record when veteran lazy loading is merged
  def establish_claim_in_vbms(end_product)
    VBMSService.establish_claim!(
      claim_hash: end_product.to_vbms_hash,
      veteran_hash: veteran.load_bgs_record!.to_vbms_hash
    )
  end

  def fetch_established_end_product
    return nil unless end_product_reference_id

    result = veteran.end_products.find do |end_product|
      end_product.claim_id == end_product_reference_id
    end

    fail EstablishedEndProductNotFound unless result
    result
  end
end
