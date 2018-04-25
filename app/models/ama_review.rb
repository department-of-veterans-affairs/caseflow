class AmaReview < ApplicationRecord
  class EstablishedEndProductNotFound < StandardError; end
  class InvalidEndProductError < StandardError; end

  belongs_to :user

  AMA_BEGIN_DATE = Date.new(2018, 4, 17).freeze

  self.abstract_class = true

  attr_reader :saving_review

  # TODO Update these for AMA
  END_PRODUCT_DATA_BY_OPTION = {
    "supplemental_claim" => { code: "683SCRRRAMP", modifier: "683" },
    "higher_level_review" => { code: "682HLRRRAMP", modifier: "682" },
    "higher_level_review_with_hearing" => { code: "682HLRRRAMP", modifier: "682" }
  }.freeze

  END_PRODUCT_STATION = "499".freeze # National Work Queue

  # If an EP with the exact same traits has already been created. Use that instead
  # of creating a new EP. This prevents duplicate EP errors and allows this method
  # to be idempotent
  #
  # Returns a symbol designating whether the end product was created or connected
  def create_or_connect_end_product!
    return connect_end_product! if matching_end_product

    create_end_product! && :created
  end

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

  def end_product_description
    end_product_reference_id && end_product.description_with_routing
  end

  def pending_end_product_description
    # This is for EPs not yet created or that failed to create
    end_product.modifier
  end

  private

  def veteran
    @veteran ||= Veteran.new(file_number: veteran_file_number)
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

  # Find an end product that has the traits of the end product that should be created.
  def matching_end_product
    @matching_end_product ||= veteran.end_products.find { |ep| end_product.matches?(ep) }
  end

  def connect_end_product!
    update!(
      end_product_reference_id: matching_end_product.claim_id,
      established_at: Time.zone.now
    ) && :connected
  end

  def end_product_data_hash
    END_PRODUCT_DATA_BY_OPTION[option_selected] || {}
  end

  def establish_claim_in_vbms(end_product)
    VBMSService.establish_claim!(
      claim_hash: end_product.to_vbms_hash,
      veteran_hash: veteran.load_bgs_record!.to_vbms_hash
    )
  end

end
