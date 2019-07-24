class HearingDay < ApplicationRecord
  self.ignored_columns = ["created_by", "updated_by"]
end

class RemoveUpdatedByAndCreatedByColumnsFromHearingDays < ActiveRecord::Migration[5.1]
  def change
    safety_assured do
      remove_column :hearing_days, :created_by
      remove_column :hearing_days, :updated_by
    end
  end
end
