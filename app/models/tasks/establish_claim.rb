require "vbms"

class EstablishClaim < Task
  include CachedAttributes

  class InvalidClaimError < StandardError; end
  class EndProductAlreadyExistsError < StandardError; end

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
        :vbms_id
      ]
    )
  end

  # Core method responsible for API call to VBMS to create the end product
  # On success, will update the DB with the data related to the outcome
  def perform!(claim_params)
    claim = EstablishClaim::Claim.new(claim_params)

    fail InvalidClaimError unless claim.valid?

    transaction do
      appeal.update!(dispatched_to_station: claim.station_of_jurisdiction)
      update_claim_establishment!(ep_code: claim.end_product_code)

      establish_claim_in_vbms(claim).tap do |end_product|
        review!(outgoing_reference_id: end_product.claim_id)
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

  private

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

  def establish_claim_in_vbms(claim)
    Appeal.repository.establish_claim!(claim: claim.to_hash, appeal: appeal)
  end

  def parse_vbms_error(error)
    case error.body
    when /PIF is already in use/
      return EndProductAlreadyExistsError
    when /A duplicate claim for this EP code already exists/
      return EndProductAlreadyExistsError
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
end

# Class used for validating the claim object
class EstablishClaim::Claim
  include ActiveModel::Validations

  # This is a list of the "variable attrs" that are returned from the
  # browser's End Product form
  PRESENT_VARIABLE_ATTRS =
    %i(date station_of_jurisdiction end_product_modifier end_product_code end_product_label).freeze
  BOOLEAN_VARIABLE_ATTRS =
    %i(gulf_war_registry suppress_acknowledgement_letter).freeze
  VARIABLE_ATTRS = PRESENT_VARIABLE_ATTRS + BOOLEAN_VARIABLE_ATTRS

  attr_accessor(*VARIABLE_ATTRS)

  validates(*PRESENT_VARIABLE_ATTRS, presence: true)
  validates(*BOOLEAN_VARIABLE_ATTRS, inclusion: { in: [true, false] })
  validate :end_product_code_and_label_match

  def initialize(attributes = {})
    attributes.each do |k, v|
      instance_variable_set("@#{k}", v)
    end
  end

  # TODO(jd): Consider moving this to date util in the future
  def formatted_date
    Date.strptime(date, "%m/%d/%Y")
  end

  def to_hash
    initial_hash = default_values.merge(dynamic_values)

    result = VARIABLE_ATTRS.each_with_object(initial_hash) do |attr, hash|
      val = instance_variable_get("@#{attr}")
      hash[attr] = val unless val.nil?
    end

    # override date attr, ensuring it's properly formatted
    result[:date] = formatted_date

    result
  end

  def dynamic_values
    {
      # TODO(jd): Make this attr dynamic in future PR once
      # we support routing a claim based on special issues
      # station_of_jurisdiction: "317"
    }
  end

  private

  def default_values
    {
      benefit_type_code: "1",
      payee_code: "00",
      predischarge: false,
      claim_type: "Claim"
    }
  end

  def end_product_code_and_label_match
    unless EndProduct::CODES[end_product_code] == end_product_label
      errors.add(:end_product_label, "must match end_product_code")
    end
  end
end
