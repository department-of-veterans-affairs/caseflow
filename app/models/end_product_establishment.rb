# EndProductEstablishment represents an end product that Caseflow has either established or attempted to
# establish (if the establishment was successful `established_at` will be set). The purpose of the
# end product is determined by the `source`.
#
# Most columns on EndProductEstablishment are intended to be immutable, representing the attributes of the
# end product when it was created. Exceptions are `synced_status` and `last_synced_at`, used to record
# the current status of the EP when the EndProductEstablishment is synced.

class EndProductEstablishment < ApplicationRecord
  attr_accessor :valid_modifiers
  # In decision reviews, we may create 2 end products at the same time. To avoid using
  # the same modifier, we add used modifiers to the invalid_modifiers array.
  attr_writer :invalid_modifiers
  belongs_to :source, polymorphic: true
  belongs_to :user

  CANCELED_STATUS = "CAN".freeze
  CLEARED_STATUS = "CLR".freeze

  # benefit_type_code => program_type_code
  PROGRAM_TYPE_CODES = {
    "1" => "CPL",
    "2" => "CPD"
  }.freeze

  class EstablishedEndProductNotFound < StandardError; end
  class ContentionCreationFailed < StandardError; end
  class InvalidEndProductError < StandardError; end
  class NoAvailableModifiers < StandardError; end

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
    records_ready_for_contentions = calculate_records_ready_for_contentions
    return if records_ready_for_contentions.empty?

    set_establishment_values_from_source

    contentions = records_ready_for_contentions.map do |issue|
      contention = { description: issue.contention_text }
      issue.try(:special_issues) && contention[:special_issues] = issue.special_issues
      contention
    end

    # Currently not making any assumptions about the order in which VBMS returns
    # the created contentions. Instead find the issue by matching text.

    # We don't care about duplicate text; we just care that every request issue
    # has a contention.
    create_contentions_in_vbms(contentions).each do |contention|
      record = records_ready_for_contentions.find do |r|
        r.contention_text == contention.text && r.contention_reference_id.nil?
      end

      record&.update!(contention_reference_id: contention.id)
    end

    fail ContentionCreationFailed if records_ready_for_contentions.any? { |r| r.contention_reference_id.nil? }
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

  def cancel_unused_end_product!
    # do not cancel ramp reviews for now
    return if source.is_a?(RampReview)

    if active_request_issues.empty?
      cancel!
    end
  end

  def sync!
    # There is no need to sync end_product_status if the status
    # is already inactive since an EP can never leave that state
    return true unless status_active?
    fail EstablishedEndProductNotFound unless result

    # load contentions now, in case "source" needs them.
    # this VBMS call is slow and will cause the transaction below
    # to timeout in some cases.
    contentions

    transaction do
      update!(
        synced_status: result.status_type_code,
        last_synced_at: Time.zone.now
      )
      sync_source!
      close_request_issues_if_canceled!
    end
  rescue EstablishedEndProductNotFound => e
    raise e
  rescue StandardError => e
    raise ::BGSSyncError.from_bgs_error(e, self)
  end

  def fetch_dispositions_from_vbms
    VBMSService.get_dispositions!(claim_id: reference_id)
  end

  def search_table_ui_hash
    {
      code: code,
      modifier: modifier || "",
      synced_status: synced_status,
      last_synced_at: last_synced_at
    }
  end

  def status_canceled?
    synced_status == CANCELED_STATUS
  end

  def status_cleared?(sync: false)
    sync! if sync
    synced_status == CLEARED_STATUS
  end

  def status_active?(sync: false)
    sync! if sync
    synced_status.nil? || !EndProduct::INACTIVE_STATUSES.include?(synced_status)
  end

  def associate_rating_request_issues!
    return if unassociated_rating_request_issues.empty?

    VBMSService.associate_rating_request_issues!(
      claim_id: reference_id,
      rating_issue_contention_map: rating_issue_contention_map(rating_request_issues)
    )

    RequestIssue.where(id: rating_request_issues.map(&:id)).update_all(
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

  def request_issues
    return [] unless source.try(:request_issues)

    source.request_issues.select { |ri| ri.end_product_establishment == self }
  end

  def active_request_issues
    request_issues.select { |request_issue| request_issue.removed_at.nil? && request_issue.status_active? }
  end

  def associated_rating
    @associated_rating ||= fetch_associated_rating
  end

  def sync_decision_issues!
    contention_records.each do |record|
      if record.respond_to?(:nonrating?) && record.nonrating?
        # for nonrating issues, submit immediately
        record.submit_for_processing!
        DecisionIssueSyncJob.perform_later(record)
      else
        # It seems to take at least a day for the associated rating to show up in BGS
        # after the EP is cleared. We don't want to tax the BGS ratings endpoint, so
        # we're going to wait a day before we start looking.
        record.submit_for_processing!(delay: 1.day)
      end
    end
  end

  def on_decision_issue_sync_processed(processing_request_issue)
    if decision_issues_sync_complete?(processing_request_issue)
      source.on_decision_issues_sync_processed(self)
    end
  end

  def status
    if committed?
      {
        ep_code: "EP #{cached_result.modifier || 'Unknown'}",
        ep_status: [status_type, sync_status].compact.join(", ")
      }
    else
      {
        ep_code: "",
        ep_status: establishment_status
      }
    end
  end

  private

  def status_type
    EndProduct::STATUSES[synced_status] || synced_status
  end

  def establishment_status
    if source.try(:establishment_error)
      COPY::OTHER_REVIEWS_TABLE_ESTABLISHMENT_FAILED
    else
      COPY::OTHER_REVIEWS_TABLE_ESTABLISHING
    end
  end

  def sync_status
    if request_issues.any?(&:decision_sync_error)
      COPY::OTHER_REVIEWS_TABLE_SYNCING_DECISIONS_ERROR
    elsif request_issues.any?(&:submitted_not_processed?)
      COPY::OTHER_REVIEWS_TABLE_SYNCING_DECISIONS
    end
  end

  # All records that create contentions should be an instance of ApplicationRecord with
  # a contention_reference_id column, and contention_text method
  # TODO: this can be refactored to ask the source instead of using a case statement
  def calculate_records_ready_for_contentions
    select_ready_for_contentions(contention_records)
  end

  def contention_records
    case source
    when ClaimReview then eligible_request_issues
    when DecisionDocument then source.effectuations.where(end_product_establishment: self)
    end
  end

  def decision_issues_sync_complete?(processing_request_issue)
    other_request_issues = request_issues.reject { |i| i.id == processing_request_issue.id }
    other_request_issues.all?(&:processed?)
  end

  def potential_decision_ratings
    Rating.fetch_in_range(participant_id: veteran.participant_id,
                          start_date: established_at.to_date,
                          end_date: Time.zone.today)
  end

  def cancel!
    transaction do
      # delete end product in bgs & set sync status to canceled
      BGSService.new.cancel_end_product(veteran_file_number, code, modifier)
      update!(synced_status: CANCELED_STATUS)
      close_request_issues_if_canceled!
    end
  end

  def close_request_issues_if_canceled!
    return unless status_canceled?

    request_issues.each(&:close_after_end_product_canceled!)
  end

  def fetch_associated_rating
    potential_decision_ratings.find do |rating|
      rating.associated_end_products.any? { |end_product| end_product.claim_id == reference_id }
    end
  end

  def open_request_issues
    request_issues.reject(&:closed?)
  end

  def rating_request_issues
    open_request_issues.select(&:rating?)
  end

  def unassociated_rating_request_issues
    eligible_rating_request_issues.select { |ri| ri.rating_issue_associated_at.nil? }
  end

  def eligible_request_issues
    open_request_issues.select(&:eligible?)
  end

  def eligible_rating_request_issues
    eligible_request_issues.select(&:rating?)
  end

  def select_ready_for_contentions(records)
    records.select { |r| r.contention_reference_id.nil? }
  end

  def rating_issue_contention_map(request_issues_to_associate)
    request_issues_to_associate.inject({}) do |contention_map, issue|
      contention_map[issue.contested_rating_issue_reference_id] = issue.contention_reference_id
      contention_map
    end
  end

  def invalid_modifiers
    @invalid_modifiers || []
  end

  def veteran
    @veteran ||= Veteran.find_or_create_by_file_number(veteran_file_number, sync_name: true)
  end

  def establish_claim_in_vbms(end_product)
    VBMSService.establish_claim!(
      claim_hash: end_product.to_vbms_hash,
      veteran_hash: veteran.to_vbms_hash,
      user: user
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
    @taken_modifiers ||= veteran.end_products.select(&:active?).map(&:modifier)
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
    return unless source&.respond_to?(:on_sync)

    source.on_sync(self)
  end

  def create_contentions_in_vbms(contentions)
    VBMSService.create_contentions!(
      veteran_file_number: veteran_file_number,
      claim_id: reference_id,
      contentions: contentions,
      user: user
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
      valid_modifiers: source.valid_modifiers
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
