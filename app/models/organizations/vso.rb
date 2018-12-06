class Vso < Organization
  has_one :ihp_writing_vso
  has_many :appeals, through: :vso_appeals

  def user_has_access?(user)
    return false unless user.roles.include?("VSO")

    participant_ids = user.vsos_user_represents.map { |poa| poa[:participant_id] }
    participant_ids.include?(participant_id)
  end

  def can_receive_task?(_task)
    false
  end
end
