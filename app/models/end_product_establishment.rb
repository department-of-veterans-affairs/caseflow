# EndProductEstablishment represents an end product that Caseflow has either established or attempted to
# establish (if the establishment was successful `established_at` will be set). The purpose of the
# end product is determined by the `source`.
#
# Most columns on EndProductEstablishment are intended to be immutable, representing the attributes of the
# end product when it was created. Exceptions are `synced_status` and `last_synced_at`, used to record
# the current status of the EP when the EndProductEstablishment is synced.

class EndProductEstablishment < ApplicationRecord
  class EstablishedEndProductNotFound < StandardError; end
  class ContentionCreationFailed < StandardError; end

  attr_accessor :valid_modifiers, :special_issues
  # In AMA reviews, we may create 2 end products at the same time. To avoid using
  # the same modifier, we add used modifiers to the invalid_modifiers array.
  attr_writer :invalid_modifiers
  belongs_to :source, polymorphic: true

  class InvalidEndProductError < StandardError; end
  class NoAvailableModifiers < StandardError; end

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

  # benefit_type_code => program_type_code
  PROGRAM_TYPE_CODES = {
    "1" => "CPL",
    "2" => "CPD"
  }.freeze

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
  def create_contentions!
    issues_without_contentions = request_issues_without_contentions
    return if issues_without_contentions.empty?

    set_establishment_values_from_source

    # Currently not making any assumptions about the order in which VBMS returns
    # the created contentions. Instead find the issue by matching text.
    create_contentions_in_vbms(issues_without_contentions.pluck(:description)).each do |contention|
      issue = issues_without_contentions.find do |i|
        i.description == contention.text && i.contention_reference_id.nil?
      end
      issue && issue.update!(contention_reference_id: contention.id)
    end

    fail ContentionCreationFailed if issues_without_contentions.any? { |issue| issue.contention_reference_id.nil? }
  end

  def remove_contention!(for_object)
    VBMSService.remove_contention!(contention_for_object(for_object))
    for_object.update!(removed_at: Time.zone.now)
  end

  # Committing an end product establishment is a way to signify that any other actions performed
  # as part of a larger atomic operation containing the end product establishment are also complete.
  # Those actions could be creating contentions or other end product establishments.
  # NOTE that nothing prevents methods from being called (e.g. remove_contention) once
  # a EPE is "committed". It is advisory, not transactional.
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
  rescue EstablishedEndProductNotFound => e
    raise e
  rescue StandardError => e
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

  def create_associated_rated_issues!
    request_issues_to_associate = unassociated_rated_request_issues

    is_rated = true
    return if code != source.issue_code(is_rated)
    return if request_issues_to_associate.empty?

    VBMSService.associate_rated_issues!(
      claim_id: reference_id,
      rated_issue_contention_map: rated_issue_contention_map(request_issues_to_associate)
    )

    RequestIssue.where(id: request_issues_to_associate.map(&:id)).update_all(
      rating_issue_associated_at: Time.zone.now
    )
  end

  def generate_claimant_letter!
    return if doc_reference_id
    generate_claimant_letter_in_bgs.tap do |result|
      update!(doc_reference_id: result)
    end
  end

  def generate_tracked_item!
    return if development_item_reference_id
    generate_tracked_item_in_bgs.tap do |result|
      update!(development_item_reference_id: result)
    end
  end

  private

  def request_issues
    source.request_issues.select { |ri| ri.end_product_establishment == self }
  end

  def rated_request_issues
    request_issues.select(&:rated?)
  end

  def unassociated_rated_request_issues
    rated_request_issues.select { |ri| ri.rating_issue_associated_at.nil? }
  end

  def request_issues_without_contentions
    request_issues.select { |ri| ri.contention_reference_id.nil? }
  end

  def rated_issue_contention_map(request_issues_to_associate)
    request_issues_to_associate.inject({}) do |contention_map, issue|
      contention_map[issue.rating_issue_reference_id] = issue.contention_reference_id
      contention_map
    end
  end

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
    @end_product_to_establish ||= end_product_with_modifier(find_open_modifier)
  end

  def fetched_result
    @fetched_result ||= fetch_result
  end

  def cached_result
    @cached_result ||= end_product_with_modifier
  end

  def end_product_with_modifier(the_modifier = nil)
    the_modifier ||= modifier
    EndProduct.new(
      claim_id: reference_id,
      claim_date: claim_date,
      claim_type_code: code,
      payee_code: payee_code,
      benefit_type_code: benefit_type_code,
      claimant_participant_id: claimant_participant_id,
      modifier: the_modifier,
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

    fail NoAvailableModifiers
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
    contentions.find { |contention| contention.id.to_i == for_object.contention_reference_id.to_i }
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

  def generate_claimant_letter_in_bgs
    BGSService.new.manage_claimant_letter_v2!(
      claim_id: reference_id,
      program_type_cd: PROGRAM_TYPE_CODES[benefit_type_code],
      claimant_participant_id: claimant_participant_id
    )
  end

  def generate_tracked_item_in_bgs
    BGSService.new.generate_tracked_items!(reference_id)
  end
end
