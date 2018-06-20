class CoLocatedAdminAction < Task
  after_initialize :set_assigned_to
  validates :title, inclusion: { in: Constants::CO_LOCATED_ADMIN_ACTIONS.keys.map(&:to_s) }
  validate :assigned_by_role_is_valid

  class << self
    def create(params)
      ActiveRecord::Base.multi_transaction do
        records = params.delete("titles").each_with_object([]) do |title, result|
          result << super(params.merge(title: title))
          result
        end
        if records.map(&:valid?).uniq == [true]
          AppealRepository.update_location!(records.first.appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
        end
        records
      end
    end
  end

  private

  def assigned_by_role_is_valid
    errors.add(:assigned_by, "has to be an attorney") if assigned_by && !assigned_by.attorney_in_vacols?
  end

  def set_assigned_to
    self.assigned_to = User.find_or_create_by(
      css_id: Constants::CoLocatedTeams::USERS[Rails.current_env].sample,
      station_id: User::BOARD_STATION_ID
    )
  end
end
