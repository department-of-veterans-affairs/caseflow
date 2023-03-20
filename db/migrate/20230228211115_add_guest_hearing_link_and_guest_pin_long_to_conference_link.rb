class AddGuestHearingLinkAndGuestPinLongToConferenceLink < Caseflow::Migration
  def change
    add_column :conference_links, :guest_hearing_link, :string, comment: "Guest link for hearing daily docket."
    add_column :conference_links, :guest_pin_long, :string, comment: "Pin provided for the guest, allowing them entry into the video conference."
  end
end
