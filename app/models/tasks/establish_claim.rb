class EstablishClaim < Task
  include CachedAttributes

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

  private

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
    completed? && [:completed, :routed_to_ro].any? do |status|
      completion_status == Task.completion_status_code(status)
    end
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
end
