# frozen_string_literal: true

class Vso < Representative
  def user_has_access?(user)
    return false unless user.roles.include?("VSO")

    participant_ids = user.vsos_user_represents.map { |poa| poa[:participant_id] }
    participant_ids.include?(participant_id)
  end

  private

  def default_ihp_dockets
    [Constants.AMA_DOCKETS.evidence_submission, Constants.AMA_DOCKETS.direct_review]
  end
end
