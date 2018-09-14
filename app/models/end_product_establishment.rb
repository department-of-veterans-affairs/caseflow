# EndProductEstablishment represents an end product that Caseflow has either established or attempted to
# establish (if the establishment was successful `established_at` will be set). The purpose of the
# end product is determined by the `source`.
#
# Most columns on EndProductEstablishment are intended to be immutable, representing the attributes of the
# end product when it was created. Exceptions are `synced_status` and `last_synced_at`, used to record
# the current status of the EP when the EndProductEstablishment is synced.

class EndProductEstablishment < ApplicationRecord
  class EstablishedEndProductNotFound < StandardError; end

  attr_accessor :valid_modifiers, :special_issues
  # In AMA reviews, we may create 2 end products at the same time. To avoid using
  # the same modifier, we add used modifiers to the invalid_modifiers array.
  attr_writer :invalid_modifiers
  belongs_to :source, polymorphic: true

  class InvalidEndProductError < StandardError; end

  class BGSSyncError < RuntimeError
    def initialize(error, end_product_establishment)
      Raven.extra_context(end_product_establishment: end_product_establishment.id)
      super(error.message).tap do |result|
        result.set_backtrace(error.backtrace)
      end
    end
  end

  CANCELED_STATUS = "CAN".freeze
  CLEARED_STATUS = "CLR".freeze

  class << self
    def order_by_sync_priority
      active.order("last_synced_at IS NOT NULL, last_synced_at ASC")
    end

    private

    def established
      where.not("established_at IS NULL")
    end

    def active
      # We only know the set of inactive EP statuses
      # We also only know the EP status after fetching it from BGS
      # Therefore, our definition of active is when the EP is either
      #   not known or not known to be inactive
      established.where("synced_status NOT IN (?) OR synced_status IS NULL", EndProduct::INACTIVE_STATUSES)
    end
  end

  def perform!(commit: false)
    return if reference_id

    set_establishment_values_from_source

    fail InvalidEndProductError unless end_product_to_establish.valid?

    establish_claim_in_vbms(end_product_to_establish).tap do |result|
      update!(
        reference_id: result.claim_id,
        established_at: Time.zone.now,
        committed_at: commit ? Time.zone.now : nil,
        modifier: end_product_to_establish.modifier
      )
    end
  rescue VBMS::HTTPError => error
    raise Caseflow::Error::EstablishClaimFailedInVBMS.from_vbms_error(error)
  end

  # VBMS will return ALL contentions on a end product when you create contentions,
  # not just the ones that were just created.
  def create_contentions!(for_objects)
    set_establishment_values_from_source

    # Currently not making any assumptions about the order in which VBMS returns
    # the created contentions. Instead find the issue by matching text.
    create_contentions_in_vbms(for_objects.pluck(:description)).each do |contention|
      matching_object = for_objects.find { |object| object.description == contention.text }
      matching_object && matching_object.update!(contention_reference_id: contention.id)
    end

    fail ContentionCreationFailed if for_objects.any? { |object| !object.contention_reference_id }
  end

  def remove_contention!(for_object)
    VBMSService.remove_contention!(contention_for_object(for_object))
    for_object.update!(removed_at: Time.zone.now)
  end

  # Committing an end product establishment is a way to signify that any other actions performed
  # as part of a larger atomic operation containing the end product establishment are also complete.
  # Those actions could be creating contentions or other end product establishments.
  def commit!
    update!(committed_at: Time.zone.now) unless committed?
  end

  def committed?
    !!committed_at
  end

  def ep_created?
    !!reference_id
  end

  # Fetch the resulting end product from the reference_id
  # Add option to either load from BGS or just used cached values
  def result(cached: false)
    cached ? cached_result : fetched_result
  end

  delegate :contentions, to: :cached_result

  def description
    reference_id && cached_result.description_with_routing
  end

  # Find an end product that has the traits of the end product that should be created.
  def preexisting_end_product
    @preexisting_end_product ||= veteran.end_products.find { |ep| end_product_to_establish.matches?(ep) }
  end

  def sync!
    # There is no need to sync end_product_status if the status
    # is already inactive since an EP can never leave that state
    return true unless status_active?

    fail EstablishedEndProductNotFound unless result

    transaction do
      update!(
        synced_status: result.status_type_code,
        last_synced_at: Time.zone.now
      )

      sync_source!
    end

    # TODO: This is sort of janky. Let's rethink the error handling logic here
  rescue StandardError => e
    raise e if e.is_a?(EstablishedEndProductNotFound)
    raise BGSSyncError.new(e, self)
  end

  def status_canceled?
    synced_status == CANCELED_STATUS
  end

  def status_cleared?
    synced_status == CLEARED_STATUS
  end

  def status_active?(sync: false)
    sync! if sync
    !EndProduct::INACTIVE_STATUSES.include?(synced_status)
  end

  private

  def invalid_modifiers
    @invalid_modifiers || []
  end

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
      payee_code: payee_code,
      claimant_participant_id: claimant_participant_id,
      modifier: find_open_modifier,
      suppress_acknowledgement_letter: false,
      gulf_war_registry: false,
      station_of_jurisdiction: station
    )
  end

  def fetched_result
    @fetched_result ||= fetch_result
  end

  def cached_result
    @cached_result ||= EndProduct.new(
      claim_id: reference_id,
      claim_date: claim_date,
      claim_type_code: code,
      payee_code: payee_code,
      claimant_participant_id: claimant_participant_id,
      modifier: modifier,
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

  def taken_modifiers
    @taken_modifiers ||= veteran.end_products.map(&:modifier)
  end

  def find_open_modifier
    return valid_modifiers.first if valid_modifiers.count == 1

    valid_modifiers.each do |modifier|
      if !(taken_modifiers + invalid_modifiers).include?(modifier)
        return modifier
      end
    end
  end

  def sync_source!
    return unless source && source.respond_to?(:on_sync)
    source.on_sync(self)
  end

  def create_contentions_in_vbms(descriptions)
    VBMSService.create_contentions!(
      veteran_file_number: veteran_file_number,
      claim_id: reference_id,
      contention_descriptions: descriptions,
      special_issues: special_issues || []
    )
  end

  def contention_for_object(for_object)
    contentions.find { |contention| contention.id == for_object.contention_reference_id }
  end

  # These are values that need to be determined based on the source right before the end
  # product is established. There is a potential to refactor this method away.
  def set_establishment_values_from_source
    self.attributes = {
      invalid_modifiers: source.respond_to?(:invalid_modifiers) && source.invalid_modifiers,
      valid_modifiers: source.valid_modifiers,
      special_issues: source.respond_to?(:special_issues) && source.special_issues
    }
  end
end
