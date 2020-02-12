# frozen_string_literal: true

RSpec.feature "Remove a Hearing Day", :postgres do
  let!(:current_user) do
    user = create(:user, css_id: "BVATWARNER", roles: ["Build HearSched"])
    HearingsManagement.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  let!(:hearing_day) do
    create(:hearing_day, request_type: "C", room: "2")
  end

  context "When removing an existing hearing day" do
    scenario "select and remove a hearing day" do
      visit "hearings/schedule"
      find_link(hearing_day.scheduled_for.strftime("%a %-m/%d/%Y")).click
      expect(page).to have_content("Remove Hearing Day")
      expect(page).to have_content("No Veterans are scheduled for this hearing day.")
      find("button", text: "Remove Hearing Day").click
      text = "Once the hearing day is removed, users will no longer be able " \
             "to schedule Veterans for this Central hearing day"
      expect(page).to have_content(text)
      find("button", text: "Confirm").click
      expect(page).to have_content(COPY::HEARING_SCHEDULE_VIEW_PAGE_HEADER)
    end
  end
end
