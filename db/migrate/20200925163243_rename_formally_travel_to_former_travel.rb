class RenameFormallyTravelToFormerTravel < Caseflow::Migration
  def change
    safety_assured do
      rename_column :cached_appeal_attributes, :formally_travel, :former_travel
      rename_index :cached_appeal_attributes, :index_cached_appeal_on_hearing_request_type_and_formally_travel, :index_cached_appeal_on_hearing_request_type_and_former_travel
      change_column_comment :cached_appeal_attributes, :former_travel, "Determines if the hearing type was formerly travel board; only applicable to Legacy appeals"
    end
  end
end
