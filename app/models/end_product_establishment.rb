# frozen_string_literal: true

# EndProductEstablishment represents an end product that Caseflow has either established or attempted to
# establish (if the establishment was successful `established_at` will be set). The purpose of the
# end product is determined by the `source`.
#
# Most columns on EndProductEstablishment are intended to be immutable, representing the attributes of the
# end product when it was created. Exceptions are `synced_status` and `last_synced_at`, used to record
# the current status of the EP when the EndProductEstablishment is synced.

class EndProductEstablishment < CaseflowRecord
  belongs_to :source, polymorphic: true
  belongs_to :user
  has_many :request_issues
  has_many :end_product_code_updates
  has_many :effectuations, class_name: "BoardGrantEffectuation"
  has_many :end_product_updates

  # allow @veteran to be assigned to save upstream calls
  attr_writer :veteran

  CANCELED_STATUS = "CAN"
  CLEARED_STATUS = "CLR"

  # benefit_type_code => program_type_code
  PROGRAM_TYPE_CODES = {
    "1" => "CPL",
    "2" => "CPD"
  }.freeze

  class EstablishedEndProductNotFound < StandardError; end
  class ContentionCreationFailed < StandardError; end
  class InvalidEndProductError < StandardError; end
  class ContentionNotFound < StandardError; end

  class << self
    def order_by_sync_priority
      active.order("last_synced_at IS NOT NULL, last_synced_at ASC")
    end

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

    save_recovered_end_product!
    return if reference_id

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

  def establish!
    return unless status_active?

    perform!
    create_contentions!
    associate_rating_request_issues!

    if source.try(:informal_conference)
      generate_claimant_letter!
      generate_tracked_item!
    end

    commit!
  end

  # VBMS will return ALL contentions on a end product when you create contentions,
  # not just the ones that were just created.
  def create_contentions!
    records_ready_for_contentions = calculate_records_ready_for_contentions
    return if records_ready_for_contentions.empty?

    contentions = build_contentions(records_ready_for_contentions)

    # VBMS returns all the contentions on the claim, old and new, so keep track
    # of existing contentions we know about. That way if text matches we can avoid false positives.
    existing_contention_reference_ids = all_contention_records.pluck(:contention_reference_id).compact.uniq.map(&:to_s)

    # Currently not making any assumptions about the order in which VBMS returns
    # the created contentions. Instead find the issue by matching text.

    # We don't care about duplicate text; we just care that every request issue has a contention.
    create_contentions_in_vbms(contentions).each do |contention|
      next if existing_contention_reference_ids.include?(contention.id)

      record = records_ready_for_contentions.find do |r|
        contention.claim_id == reference_id &&
          r.contention_text == contention.text &&
          r.contention_reference_id.nil?
      end

      record&.update!(contention_reference_id: contention.id)
    end

    fail ContentionCreationFailed if records_ready_for_contentions.any? { |r| r.contention_reference_id.nil? }
  end

  def build_contentions(records_ready_for_contentions)
    records_ready_for_contentions.map do |issue|
      contention = { description: issue.contention_text, contention_type: issue.contention_type }
      issue.try(:special_issues) && contention[:special_issues] = issue.special_issues

      if FeatureToggle.enabled?(:send_original_dta_contentions, user: RequestStore.store[:current_user])
        issue.try(:original_contention_ids) && contention[:original_contention_ids] = issue.original_contention_ids
      end

      contention
    end
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

  alias end_product result

  delegate :contentions, :bgs_contentions, to: :cached_result

  def limited_poa_on_established_claim
    result&.limited_poa
  end

  def description
    reference_id && cached_result.description_with_routing
  end

  def rating?
    EndProductCodeSelector::END_PRODUCT_CODES.find_all_values_for(:rating).include?(code)
  end

  def nonrating?
    EndProductCodeSelector::END_PRODUCT_CODES.find_all_values_for(:nonrating).include?(code)
  end

  # The last action date helps approximate when an EP was cleared. However, some EPs are missing this data
  # Since we stop syncing EPs once they're cleared, the last_synced_at is our best guess when it's missing
  def last_action_date
    result&.last_action_date || last_synced_at&.to_date
  end

  # Find an end product that has the traits of the end product that should be created.
  def active_preexisting_end_product
    preexisting_end_products.find(&:active?)
  end

  def preexisting_end_products
    @preexisting_end_products ||= veteran.end_products.select { |ep| end_product_to_establish.matches?(ep) }
  end

  def cancel_unused_end_product!
    # do not cancel ramp reviews for now
    return if source.is_a?(RampReview)

    if request_issues.active.empty?
      cancel!
    end
  end

  def sync!
    # There is no need to sync end_product_status if the status
    # is already inactive since an EP can never leave that state
    return true unless status_active?

    fail EstablishedEndProductNotFound, id unless result

    # load contentions now, in case "source" needs them.
    # this VBMS call is slow and will cause the transaction below
    # to timeout in some cases.
    contentions unless result.status_type_code == EndProduct::STATUSES.key("Canceled")

    transaction do
      update!(
        synced_status: result.status_type_code,
        last_synced_at: Time.zone.now
      )
      status_cancelled? ? handle_cancelled_ep! : sync_source!
      close_request_issues_with_no_decision!
    end

    save_updated_end_product_code!
  rescue EstablishedEndProductNotFound, AppealRepository::AppealNotValidToReopen => error
    raise error
  rescue StandardError => error
    Raven.extra_context(end_product_establishment_id: id)
    raise error
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

  def status_cancelled?
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
      rating_issue_contention_map: rating_issue_contention_map(rating_request_issues_to_associate)
    )

    RequestIssue.where(id: rating_request_issues_to_associate.map(&:id)).update_all(
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

  def associated_rating_cache_key
    "end_product_establishments/#{id}/associated_rating"
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
      source.on_decision_issues_sync_processed
    end
  end

  def status
    ep_code = Constants::EP_CLAIM_TYPES[code]
    if committed?
      {
        ep_code: "#{modifier} #{ep_code ? ep_code['official_label'] : 'Unknown'}",
        ep_status: [status_type, sync_status].compact.join(", ")
      }
    else
      {
        ep_code: "",
        ep_status: establishment_status
      }
    end
  end

  def contention_for_object(for_object)
    contentions.find { |contention| contention.id.to_i == for_object.contention_reference_id.to_i }
  end

  def bgs_contention_for_object(for_object)
    bgs_contentions.find { |contention| contention.reference_id.to_i == for_object.contention_reference_id.to_i }
  end

  def veteran
    @veteran ||= Veteran.find_or_create_by_file_number(veteran_file_number, sync_name: true)
  end

  # In order to expedite processing, EPs originating from the board are set to "Ready for Decision"
  def status_type_code
    ready_for_decision_codes = EndProduct::EFFECTUATION_CODES.merge(EndProduct::REMAND_CODES)

    if ready_for_decision_codes.include?(code)
      EndProduct::STATUSES.key("Ready for decision")
    else
      EndProduct::STATUSES.key("Pending")
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
    if request_issues.all.any?(&:decision_sync_error)
      COPY::OTHER_REVIEWS_TABLE_SYNCING_DECISIONS_ERROR
    elsif request_issues.all.any?(&:submitted_not_processed?) && !request_issues.all.any?(&:closed?)
      COPY::OTHER_REVIEWS_TABLE_SYNCING_DECISIONS
    end
  end

  def calculate_records_ready_for_contentions
    select_ready_for_contentions(contention_records)
  end

  # All records that create contentions should be an instance of ApplicationRecord with
  # a contention_reference_id column, and contention_text method
  def contention_records
    source.contention_records(self)
  end

  def all_contention_records
    source.all_contention_records(self)
  end

  def decision_issues_sync_complete?(processing_request_issue)
    other_request_issues = request_issues.all.reject { |i| i.id == processing_request_issue.id }
    other_request_issues.all? { |i| i.closed? || i.processed? }
  end

  def potential_decision_ratings
    RatingAtIssue.fetch_in_range(
      participant_id: veteran.participant_id,
      start_date: established_at.to_date,
      end_date: Time.zone.today
    )
  end

  def cancel!
    transaction do
      # delete end product in bgs & set sync status to canceled
      BGSService.new.cancel_end_product(veteran_file_number, code, modifier, payee_code, benefit_type_code)
      update!(synced_status: CANCELED_STATUS)
      handle_cancelled_ep!
    end
  end

  def handle_cancelled_ep!
    return unless status_cancelled?

    source.try(:canceled!)
    request_issues.all.find_each(&:close_after_end_product_canceled!)
  end

  def close_request_issues_with_no_decision!
    return unless status_cleared?
    return unless result.claim_type_code.include?("400")

    request_issues.each { |ri| RequestIssueClosure.new(ri).with_no_decision! }
  end

  # This looks for a new rating associated to this end product when deciding the claim
  # Not to be confused with associating contentions to rating issues when establishing a claim
  def fetch_associated_rating
    Rails.cache.fetch(associated_rating_cache_key, expires_in: 3.hours) do
      potential_decision_ratings.find do |rating|
        rating.associated_end_products.any? { |end_product| end_product.claim_id == reference_id }
      end
    end
  end

  def rating_request_issues_to_associate
    request_issues.active.all.select(&:associated_rating_issue?)
  end

  def unassociated_rating_request_issues
    request_issues.active.rating.all.select { |ri| ri.associated_rating_issue? && ri.rating_issue_associated_at.nil? }
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

  def establish_claim_in_vbms(end_product)
    veteran.unload_bgs_record

    VBMSService.establish_claim!(
      claim_hash: end_product.to_vbms_hash,
      veteran_hash: veteran.to_vbms_hash,
      user: user
    )
  end

  def end_product_to_establish
    @end_product_to_establish ||= end_product_with_modifier(open_modifier)
  end

  def open_modifier
    @open_modifier ||= EndProductModifierFinder.new(self, veteran).find
  end

  def fetched_result
    @fetched_result ||= fetch_result
  end

  def cached_result
    @cached_result ||= end_product_with_modifier
  end

  # Fetch and cache an EP whose attributes match this EPE (or nil if none found)
  # The complicated version of ||= is used because nil is a common value for this method.
  def matching_established_end_product
    return @matching_established_end_product if defined?(@matching_established_end_product)

    @matching_established_end_product = veteran.end_products.find do |end_product|
      matches_end_product?(end_product)
    end
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
      station_of_jurisdiction: station,
      limited_poa_code: limited_poa_code,
      limited_poa_access: limited_poa_access,
      status_type_code: status_type_code
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

  def matches_end_product?(end_product)
    return true if ep_created? && reference_id == end_product.claim_id
    return false unless end_product.active? &&
                        end_product.claim_type_code == code &&
                        end_product.claim_date == claim_date &&
                        end_product.payee_code == payee_code

    # Call it a match once we confirm that other EPE has the same claim ID
    EndProductEstablishment.find_by(reference_id: end_product.claim_id).nil?
  end

  def sync_source!
    return unless source&.respond_to?(:on_sync)

    source.on_sync(self)
  end

  def save_updated_end_product_code!
    if code != result.claim_type_code
      return if result.claim_type_code == end_product_code_updates.last&.code

      end_product_code_updates.create(code: result.claim_type_code)
    end
  end

  def save_recovered_end_product!
    return unless source.try(:previously_attempted?)

    if matching_established_end_product.present?
      update!(
        reference_id: matching_established_end_product.claim_id,
        established_at: Time.zone.now,
        modifier: matching_established_end_product.modifier
      )
    end
  end

  def create_contentions_in_vbms(contentions)
    VBMSService.create_contentions!(
      veteran_file_number: veteran_file_number,
      claim_id: reference_id,
      contentions: contentions,
      user: user,
      claim_date: claim_date
    )
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
