class AddMeetingTypeToVirtualHearings < Caseflow::Migration[5.2]
  def change
    add_column :virtual_hearings, :meeting_type, :varChar, comment: "Video Conferencing Application Type"
  end
end
