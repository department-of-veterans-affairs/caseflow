class AddMeetingTypeToConferenceLinks < Caseflow::Migration
  def change
    add_column :conference_links, :meeting_type, :varChar, comment: "Video Conferencing Application Type"
  end
end
