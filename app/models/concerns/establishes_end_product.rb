module EstablishesEndProduct
  extend ActiveSupport::Concern

  class EstablishedEndProductNotFound < StandardError; end

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
    end_product_establishment.perform!

    update!(
      end_product_reference_id: end_product_establishment.reference_id,
      established_at: Time.zone.now
    )
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

  def end_product_establishment
    @end_product_establishment ||= EndProductEstablishment.new(
      veteran: veteran,
      reference_id: end_product_reference_id,
      claim_date: receipt_date,
      code: end_product_code,
      valid_modifiers: valid_modifiers,
      station: "397",
      cached_status: end_product_status
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
