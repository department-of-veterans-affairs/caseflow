class AddAppealSeriesRefToAppeals < ActiveRecord::Migration
  def change
    add_reference :appeals, :appeal_series, foreign_key: true
  end
end
