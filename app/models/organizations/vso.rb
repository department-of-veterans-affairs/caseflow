class Vso < Organization
  def user_has_access?(user)
    participant_ids = user.vsos.map { |poa| poa[:participant_id] }
    participant_ids.include?(participant_id)
  end

  def path
    "/organization/#{url}"
  end
end
