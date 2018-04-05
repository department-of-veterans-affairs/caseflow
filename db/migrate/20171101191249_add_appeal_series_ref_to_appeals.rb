class AddAppealSeriesRefToAppeals < ActiveRecord::Migration[5.1]
  def change
    add_reference :appeals, :appeal_series, foreign_key: true
  end
end
