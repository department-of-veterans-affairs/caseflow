class EstablishClaim < Task
  include CachedAttributes

  has_one :claim_establishment, foreign_key: :task_id

  cache_attribute :cached_decision_type do
    appeal.decision_type
  end

  cache_attribute :cached_veteran_name do
    appeal.veteran_name
  end

  def actions_taken
    return [] if !completed?

    actions = ["Reviewed #{cached_decision_type} decision"]
    actions << "VACOLS Updated: Changed Location to #{location_changed_to}" if location_changed_to
    actions << "VACOLS Updated: Added Diary Note on #{special_issues}" if vacols_note_added?
    actions << "Added VBMS Note on #{special_issues}" if vbms_note_added?
    actions << "Processed case outside of Caseflow" if special_issue_not_emailed?
    actions
  end

  private

  def location_changed_to
    @location_changed_to ||= AppealRepository.location_after_dispatch(appeal)
  end

  def vbms_note_added?
    ep_created? && appeal.special_issues?
  end

  def vacols_note_added?
    location_changed_to && location_changed_to != "397"
  end

  def special_issues
    appeal.special_issues.join("; ")
  end
end
