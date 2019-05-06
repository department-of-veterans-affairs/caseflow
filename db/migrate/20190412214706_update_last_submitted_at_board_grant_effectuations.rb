class BoardGrantEffectuation < ApplicationRecord
  self.ignored_columns = ["last_submitted_at"]
end

class UpdateLastSubmittedAtBoardGrantEffectuations < ActiveRecord::Migration[5.1]
  def up
    safety_assured do
      execute "UPDATE board_grant_effectuations SET decision_sync_last_submitted_at=last_submitted_at"
    end
  end

  def down
    safety_assured do
      execute "UPDATE board_grant_effectuations SET last_submitted_at=decision_sync_last_submitted_at"
    end
  end
end
