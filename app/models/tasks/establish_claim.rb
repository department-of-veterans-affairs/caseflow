class EstablishClaim < Task
  include CachedAttributes

  class InvalidEndProductError < StandardError; end

  class VBMSError < StandardError
    attr_reader :error_code

    def initialize(error_code)
      @error_code = error_code
    end
  end

  has_one :claim_establishment, foreign_key: :task_id
  after_create :init_claim_establishment!

  cache_attribute :cached_decision_type do
    appeal.decision_type
  end

  cache_attribute :cached_veteran_name do
    appeal.veteran_name
  end

  cache_attribute :cached_serialized_decision_date do
    appeal.serialized_decision_date
  end

  cache_attribute :cached_outcoded_by do
    appeal.outcoded_by_name
  end

  def to_hash
    serializable_hash(
      include: [:user],
      methods: [
        :progress_status,
        :days_since_creation,
        :completion_status_text,
        :cached_decision_type,
        :cached_veteran_name,
        :cached_serialized_decision_date,
        :cached_outcoded_by,
        :vbms_id
      ]
    )
  end

  # Used when processing the task.
  # Makes calls to BGS, which can make it much slower.
  def to_hash_with_bgs_call
    serializable_hash(
      include: [:user, appeal: {
        include: [
          :pending_eps,
          :non_canceled_end_products_within_30_days,
          decisions: { methods: :received_at }
        ],
        methods: [
          :serialized_decision_date,
          :disposition,
          :veteran_name,
          :decision_type,
          :station_key,
          :regional_office_key,
          :issues,
          :sanitized_vbms_id
        ] }],
      methods: [:progress_status, :aasm_state]
    )
  end

  # Core method responsible for API call to VBMS to create the end product
  # On success, will update the DB with the data related to the outcome
  def perform!(end_product_params)
    end_product = EndProduct.from_establish_claim_params(end_product_params)

    fail InvalidEndProductError unless end_product.valid?

    transaction do
      appeal.update!(dispatched_to_station: end_product.station_of_jurisdiction)
      update_claim_establishment!(ep_code: end_product.claim_type_code)

      establish_claim_in_vbms(end_product).tap do |result|
        review!(outgoing_reference_id: result.claim_id)
      end
    end

  rescue VBMS::HTTPError => error
    raise parse_vbms_error(error)
  end

  def complete_with_review!(vacols_note:)
    transaction do
      update_claim_establishment!
      complete!(status: completion_status_after_review)
      Appeal.repository.update_vacols_after_dispatch!(appeal: appeal, vacols_note: vacols_note)
    end
  end

  def complete_with_email!(email_recipient:, email_ro_id:)
    transaction do
      update_claim_establishment!(email_recipient: email_recipient, email_ro_id: email_ro_id)
      complete!(status: :special_issue_emailed)
    end
  end

  def assign_existing_end_product!(end_product_id)
    transaction do
      update_claim_establishment!
      complete!(status: :assigned_existing_ep, outgoing_reference_id: end_product_id)
      Appeal.repository.update_location_after_dispatch!(appeal: appeal)
    end
  end

  def prepare_with_decision!
    try_prepare_with_decision!.tap do |result|
      Rails.logger.info "Prepared EstablishClaim (id = #{id}), Result: #{result}"
    end
  end

  def actions_taken
    [
      decision_reviewed_action_description,
      ep_establishment_action_description,
      change_location_action_description,
      vacols_note_action_description,
      vbms_not_action_description,
      email_sent_action_description,
      not_emailed_action_description
    ].reject(&:nil?)
  end

  def time_to_complete
    return nil if !appeal.outcoding_date || !created_at
    completed_at - appeal.outcoding_date
  end

  def completion_status_text
    case completion_status
    when "routed_to_ro"
      "EP created for RO #{ep_ro_description}"
    when "special_issue_emailed"
      "Emailed - #{special_issues} Issue(s)"
    else
      super
    end
  end

  def bgs_info_valid?
    appeal.veteran.valid?
  end

  def should_invalidate?
    !appeal.vacols_record_exists? ||
      !appeal.decision_date ||
      !appeal.decision_type ||
      appeal.status == "Active"
  end

  private

  def try_prepare_with_decision!
    return :invalid if check_and_invalidate!
    return :already_prepared unless may_prepare?
    return :missing_decision if appeal.decisions.empty?

    begin
      appeal.decisions.each(&:fetch_and_cache_document_from_vbms)
    rescue VBMS::ClientError => e
      Rails.logger.info "Failed EstablishClaim (id = #{id}), Error: #{e}"
      return :failed
    end

    prepare! && :success
  end

  def init_claim_establishment!
    create_claim_establishment(appeal: appeal)
  end

  # Update the claim establishment with the most fresh values from vacols
  # Also allow attrs from the claim establishment to be passed in
  def update_claim_establishment!(attrs = {})
    return unless claim_establishment

    claim_establishment.appeal = appeal
    claim_establishment.update!(attrs)
  end

  def establish_claim_in_vbms(end_product)
    VBMSService.establish_claim!(
      claim_hash: end_product.to_vbms_hash,
      veteran_hash: appeal.veteran.to_vbms_hash
    )
  end

  def parse_vbms_error(error)
    case error.body
    when /PIF is already in use/
      return VBMSError.new("duplicate_ep")
    when /A duplicate claim for this EP code already exists/
      return VBMSError.new("duplicate_ep")
    when /The PersonalInfo SSN must not be empty./
      return VBMSError.new("missing_ssn")
    else
      return error
    end
  end

  def decision_reviewed_action_description
    completed? ? "Reviewed #{cached_decision_type} decision" : nil
  end

  def ep_establishment_action_description
    ep_created? ? "Established EP: #{established_ep_description}" : nil
  end

  def change_location_action_description
    location_changed? ? "VACOLS Updated: Changed Location to #{location_changed_to}" : nil
  end

  def vacols_note_action_description
    vacols_note_added? ? "VACOLS Updated: Added Diary Note on #{special_issues}" : nil
  end

  def vbms_not_action_description
    vbms_note_added? ? "Added VBMS Note on #{special_issues}" : nil
  end

  def email_sent_action_description
    return nil unless sent_email
    "Sent email to: #{sent_email.recipient} in #{sent_email.ro_name} - re: #{special_issues} Issue(s)"
  end

  def not_emailed_action_description
    special_issue_not_emailed? ? "Processed case outside of Caseflow" : nil
  end

  def location_changed_to
    @location_changed_to ||= AppealRepository.location_after_dispatch(appeal: appeal)
  end

  def location_changed?
    completed? && location_changed_to
  end

  def vbms_note_added?
    ep_created? && appeal.special_issues?
  end

  def vacols_note_added?
    location_changed? && appeal.dispatched_to_station != "397"
  end

  def special_issues
    appeal.special_issues.join("; ")
  end

  def sent_email
    claim_establishment && claim_establishment.sent_email
  end

  def ep_created?
    outgoing_reference_id && !assigned_existing_ep?
  end

  def established_ep_description
    if claim_establishment
      "#{claim_establishment.ep_description} for #{ep_ro_description}"
    else
      # TODO: remove this when we are confident all tasks are receiving claim establishments
      "routed to #{ep_ro_description}"
    end
  end

  def ep_ro_description
    ep_ro ? "Station #{appeal.dispatched_to_station} - #{ep_ro[:city]}" : "Unknown"
  end

  def ep_ro
    possible_ros = [VACOLS::RegionalOffice::STATIONS[appeal.dispatched_to_station]].flatten
    possible_ros && VACOLS::RegionalOffice::CITIES[possible_ros.first]
  end

  def completion_status_after_review
    return :special_issue_vacols_routed unless ep_created?

    appeal.special_issues? ? :routed_to_ro : :routed_to_arc
  end

  class << self
    def for_full_grant
      joins_task_result.where(claim_establishments: { decision_type: 1 })
    end

    def for_partial_grant_or_remand
      joins_task_result.where(claim_establishments: { decision_type: [2, 3] })
    end

    def joins_task_result
      joins(:claim_establishment)
    end

    def past_weeks(num)
      where("completed_at >= ?", Time.zone.today - num.weeks)
    end
  end
end
