class RemoveNullConstraintOnElectionNoticeDate < ActiveRecord::Migration[5.1]
  def change
    change_column_null :ramp_elections, :notice_date, true
  end
end
