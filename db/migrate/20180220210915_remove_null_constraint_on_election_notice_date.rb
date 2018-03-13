class RemoveNullConstraintOnElectionNoticeDate < ActiveRecord::Migration
  def change
    change_column_null :ramp_elections, :notice_date, true
  end
end
