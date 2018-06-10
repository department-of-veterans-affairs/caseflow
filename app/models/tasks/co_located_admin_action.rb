class CoLocatedAdminAction < Task
  after_initialize :set_assigned_to
  validates :title, inclusion: { in: Constants::CO_LOCATED_ADMIN_ACTIONS.keys.map(&:to_s) }
  validate :assigned_by_role_is_valid

  class << self
    def create(params)
      ActiveRecord::Base.multi_transaction do
        record = super
        if record.valid?
          AppealRepository.update_location!(record.appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
        end
        record
      end
    end
  end

  private

  def assigned_by_role_is_valid
    errors.add(:assigned_by, "has to be an attorney") if assigned_by && assigned_by.vacols_role != "Attorney"
  end

  def set_assigned_to
    self.assigned_to = User.find_or_create_by(
      css_id: Constants::CoLocatedTeams::USERS[Rails.current_env].sample,
      station_id: User::BOARD_STATION_ID
    )
  end
end
