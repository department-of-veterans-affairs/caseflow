class AddPoaNameAndSuggestedHearingLocToCachedAppealAttributes < ActiveRecord::Migration[5.1]
  def change
    add_column :cached_appeal_attributes, :power_of_attorney_name, :string, comment: "'Firstname Lastname' of power of attorney"
    add_column :cached_appeal_attributes, :suggested_hearing_location, :string, comment: "Suggested hearing location in 'City, State (Facility Type)' format"
  end
end
