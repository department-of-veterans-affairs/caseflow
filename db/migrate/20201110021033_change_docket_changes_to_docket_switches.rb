class ChangeDocketChangesToDocketSwitches < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      rename_table :docket_changes, :docket_switches
      change_table_comment(:docket_switches, "Stores the disposition and associated data for Docket Switch motions.")
      change_column_comment(:docket_switches, :granted_request_issue_ids, "When a docket switch is partially granted, this includes an array of the appeal's request issue IDs that were selected for the new docket. For full grant, this includes all prior request issue IDs.")
    end
  end
end
