class RenameChangedRequestTypeToChangedHearingRequestType < Caseflow::Migration
  def up
    safety_assured do
	    rename_column :appeals, :changed_request_type, :changed_hearing_request_type
	    rename_column :legacy_appeals, :changed_request_type, :changed_hearing_request_type
	end
  end
  def down
    safety_assured do
	    rename_column :appeals, :changed_hearing_request_type, :changed_request_type
	    rename_column :legacy_appeals, :changed_hearing_request_type, :changed_request_type
	end
  end
end
