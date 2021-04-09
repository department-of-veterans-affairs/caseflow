class RenameOriginalRequestTypeToOriginalHearingRequestType < Caseflow::Migration
  def up
    safety_assured do
	    rename_column :appeals, :original_request_type, :original_hearing_request_type
	    rename_column :legacy_appeals, :original_request_type, :original_hearing_request_type
	  end
	end
  def down
    safety_assured do
	    rename_column :appeals, :original_hearing_request_type, :original_request_type
	    rename_column :legacy_appeals, :original_hearing_request_type, :original_request_type
	end
  end
end
