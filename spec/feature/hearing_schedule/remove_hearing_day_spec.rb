RSpec.feature "Remove a Hearing Day" do
  let!(:current_user) do
    OrganizationsUser.add_user_to_organization(hearings_user, HearingsManagement.singleton)
    User.authenticate!(css_id: "BVATWARNER", roles: ["Build HearSched"])
  end

  let!(:hearings_user) do
    create(:hearings_management)
  end

  let!(:hearing_day) do
    create(:hearing_day, scheduled_for: Date.new(2019, 3, 15), request_type: "C", room: "2")
  end

  context "When removing an existing hearing day" do
    scenario "select and remove a hearing day" do
      visit "hearings/schedule"
      find_link("Fri 3/15/2019").click
      expect(page).to have_content("Remove Hearing Day")
      expect(page).to have_content("No Veterans are scheduled for this hearing day.")
      find("button", text: "Remove Hearing Day").click
      expect(page).to have_content("Once the hearing day is removed, users will no
              longer be able to schedule Veterans for this Central hearing day on Fri 3/15/2019.")
      find("button", text: "Confirm").click
      expect(page).to have_content("Welcome to Hearing Schedule!")
    end
  end
end
