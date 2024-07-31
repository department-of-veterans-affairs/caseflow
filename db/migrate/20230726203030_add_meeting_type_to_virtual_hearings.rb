class AddMeetingTypeToVirtualHearings < Caseflow::Migration
  def up
    add_column :virtual_hearings, :meeting_type, :varChar, default: "pexip", comment: "Video Conferencing Application Type"
  end

  def down
    remove_column :virtual_hearings, :meeting_type
  end
end
