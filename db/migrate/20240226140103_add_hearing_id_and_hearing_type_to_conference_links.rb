class AddHearingIdAndHearingTypeToConferenceLinks < Caseflow::Migration
  disable_ddl_transaction!

  def change
    add_column :conference_links, :hearing_id, :bigint, comment: "ID of the hearing associated with this record"
    add_column :conference_links, :hearing_type, :string, comment: "Type of hearing associated with this record"

    change_column_null :conference_links, :hearing_day_id, true
  end
end
