class FixSchemaTodoComment < ActiveRecord::Migration[5.2]
  def change
    change_column_comment(:board_grant_effectuations, :last_submitted_at, "Async job processing most recent start timestamp")
  end
end
