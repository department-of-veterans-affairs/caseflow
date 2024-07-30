# frozen_string_literal: true

RSpec.feature "Hearing Schedule Daily Docket for RO ViewHearSched", :all_dbs do
  let!(:actcode) { create(:actcode, actckey: "B", actcdtc: "30", actadusr: "SBARTELL", acspare1: "59") }
  let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["RO ViewHearSched"]) }
  let!(:hearing) { create(:hearing, :with_tasks) }

  scenario "User cannot view docket notes", skip: "Flaky test" do
    visit "hearings/schedule/docket/" + hearing.hearing_day.id.to_s
    expect(page).to_not have_button("Print all Hearing Worksheets")
    expect(page).to_not have_content("Edit Hearing Day")
    expect(page).to_not have_content("Lock Hearing Day")
    expect(page).to_not have_content("Hearing Details")
    expect(page).to_not have_content("Notes")
    expect(page).to have_field("Transcript Requested", disabled: true, visible: false)
  end
end
