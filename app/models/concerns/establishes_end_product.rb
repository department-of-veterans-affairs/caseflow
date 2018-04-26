module EstablishesEndProduct
  # Requires external dependencies:
  # end_product_reference_id
  # receipt_date
  # end_product_code
  # end_product_modifier
  # end_product_station
  # veteran
  # established_at
  # established_at=

  extend ActiveSupport::Concern

  class EstablishedEndProductNotFound < StandardError; end
  class InvalidEndProductError < StandardError; end

  module ClassMethods
    def established
      where.not(established_at: nil)
    end

    def active
      # We only know the set of inactive EP statuses
      # We also only know the EP status after fetching it from BGS
      # Therefore, our definition of active is when the EP is either
      #   not known or not known to be inactive
      established.where("end_product_status NOT IN (?) OR end_product_status IS NULL", EndProduct::INACTIVE_STATUSES)
    end
  end

  def establish_end_product!
    fail InvalidEndProductError unless end_product_to_establish.valid?

    establish_claim_in_vbms(end_product_to_establish).tap do |result|
      update!(
        end_product_reference_id: result.claim_id,
        established_at: Time.zone.now
      )
    end
  rescue VBMS::HTTPError => error
    raise Caseflow::Error::EstablishClaimFailedInVBMS.from_vbms_error(error)
  end

  def end_product_active?
    sync_ep_status! && cached_status_active?
  end

  def established?
    !!established_at
  end

  def established_end_product
    @established_end_product ||= fetch_established_end_product
  end

  def end_product_canceled?
    sync_ep_status! && end_product_status == "CAN"
  end

  def sync_ep_status!
    # There is no need to sync end_product_status if the status
    # is already inactive since an EP can never leave that state
    return true unless cached_status_active?

    update!(
      end_product_status: established_end_product.status_type_code,
      end_product_status_last_synced_at: Time.zone.now
    )
  end

  private

  def cached_status_active?
    !EndProduct::INACTIVE_STATUSES.include?(end_product_status)
  end

  def end_product_to_establish
    @end_product_to_establish ||= EndProduct.new(
      claim_id: end_product_reference_id,
      claim_date: receipt_date,
      claim_type_code: end_product_code,
      modifier: end_product_modifier,
      suppress_acknowledgement_letter: false,
      gulf_war_registry: false,
      station_of_jurisdiction: end_product_station
    )
  end

  def establish_claim_in_vbms(end_product)
    VBMSService.establish_claim!(
      claim_hash: end_product.to_vbms_hash,
      veteran_hash: veteran.to_vbms_hash
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
