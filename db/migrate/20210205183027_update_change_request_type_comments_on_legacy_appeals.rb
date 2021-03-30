class UpdateChangeRequestTypeCommentsOnLegacyAppeals < ActiveRecord::Migration[5.2]
  def change
    change_column_comment :legacy_appeals, :changed_request_type, "The new hearing type preference for an appellant that needs a hearing scheduled"
  end
end
