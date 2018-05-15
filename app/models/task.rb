class Task < ApplicationRecord
  belongs_to :assigned_to, class_name: "User"
  belongs_to :assigned_by, class_name: "User"
  # TODO: add polymorphic association
  belongs_to :appeal, class_name: "LegacyAppeal"

  validates :assigned_to, :assigned_by, :appeal, :action_type, :status, presence: true

  before_create :set_assigned_at, :set_assigned_to

  # TODO: add more co-located types
  # TODO: move it to the contants file
  ACTION_TYPES = {
    co_located: {
      ihp: "IHP",
      waiver_of_aoj_letter: "Waiver of AOJ Letter",
      arneson_letter: "Arneson Letter"
    }
  }.freeze

  enum status: {
    assigned: 0,
    in_progress: 1,
    on_hold: 2,
    completed: 3
  }

  def co_located?
    ACTION_TYPES[:co_located].keys? include? action_type
  end

  private

  def set_assigned_at
    self.assigned_at = created_at
  end

  def set_assigned_to
    if co_located?
      self.assigned_to = User.find_or_create_by(
        css_id: Constants::CoLocatedTeams::USERS[Rails.current_env].sample,
        station_id: User::BOARD_STATION_ID
      )
    end
  end
end
