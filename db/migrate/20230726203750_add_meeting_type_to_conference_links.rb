class AddMeetingTypeToConferenceLinks < Caseflow::Migration
  def up
    add_column :conference_links, :meeting_type, :varChar, default: "pexip", comment: "Video Conferencing Application Type"
  end

  def down
    remove_column :conference_links, :meeting_type
  end
end
