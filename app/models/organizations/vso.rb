class Vso < Organization
  def user_has_access?(user)
    return false unless user.roles.include?("VSO")

    participant_ids = user.vsos_user_represents.map { |poa| poa[:participant_id] }
    participant_ids.include?(participant_id)
  end

  def can_receive_task?(_task)
    false
  end

  def should_write_ihp?(appeal)
    ihp_writing_configs.include?(appeal.docket_type) && appeal.vsos.include?(self)
  end

  private

  def ihp_writing_configs
    vso_config&.ihp_dockets || [Constants.AMA_DOCKETS.evidence_submission, Constants.AMA_DOCKETS.direct_review]
  end
end
