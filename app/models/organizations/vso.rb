class Vso < Organization
  def user_has_access?(user)
    user_participant_id = bgs.get_participant_id_for_user(user)
    participant_ids = bgs.fetch_poas_by_participant_id(user_participant_id).map { |poa| poa[:participant_id] }
    participant_ids.include?(self.participant_id)
  end

  private

  def bgs
    @bgs ||= BGSService.new
  end
end
