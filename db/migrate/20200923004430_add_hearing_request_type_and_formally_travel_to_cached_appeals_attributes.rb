class AddHearingRequestTypeAndFormallyTravelToCachedAppealsAttributes < Caseflow::Migration
  def change
    safety_assured do
      add_column :cached_appeal_attributes, :hearing_request_type, :string, :limit => 10, comment: "Stores hearing type requested by appellant; could be one of nil, 'Video', 'Central', 'Travel', or 'Virtual'"
      add_column :cached_appeal_attributes, :formally_travel, :boolean, comment: "Determines if the hearing type was formallly travel board; only applicable to Legacy appeals"

      add_safe_index :cached_appeal_attributes, [:hearing_request_type, :formally_travel], name: :index_cached_appeal_on_hearing_request_type_and_formally_travel
    end
  end
end
