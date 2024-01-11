# frozen_string_literal: true

RSpec.feature "AMA Non-priority Distribution Goals by Docket Levers" do
  let!(:current_user) do
    user = create(:user, css_id: "BVATTWAYNE")
    CDAControlGroup.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  context "User is in Case Distro Algorithm Control organization but not an admin" do
    scenario "visits the lever control page" do
      visit "case-distribution-controls"
      visit "acd-controls"
      expect(page).not_to have_content("Administration")
      expect(page).to have_content("AMA Non-priority Distribution Goals by Docket")
      expect(page).to have_content("AMA Direct Review")

      # expect lever to be disabled
      # expect(find(".dropdown-#{hearing.external_id}-disposition")).to have_css(".cf-select__control--is-disabled")
      # expect(page).to have_field("Transcript Requested", disabled: true, visible: false)
    end
  end

  context "User is a Case Distro Algorithm Control admin" do
    before do
      OrganizationsUser.make_user_admin(current_user, CDAControlGroup.singleton)
    end

    scenario "visits the lever control page" do
      visit "case-distribution-controls"
      expect(page).to have_content("Administration")
      expect(page).to have_content("AMA Non-priority Distribution Goals by Docket")
      expect(page).to have_content("AMA Direct Review")

      # expect lever to be enabled
      # expect(find(".dropdown-#{hearing.external_id}-disposition")).to have_css(".cf-select__control--is-disabled")
      # expect(page).to have_field("Transcript Requested", disabled: true, visible: false)
    end

    scenario "changes the AMA Direct Review lever value to an invalid input" do
      visit "case-distribution-controls"
      expect(page).to have_content("Administration")
      expect(page).to have_content("AMA Non-priority Distribution Goals by Docket")
      expect(page).to have_content("AMA Direct Review")

      fill_in "ama_direct_review_docket_time_goals", with: "ABC"

    end

    scenario "changes the AMA Direct Review lever value to a valid input" do
      visit "case-distribution-controls"
      expect(page).to have_content("Administration")
      expect(page).to have_content("AMA Non-priority Distribution Goals by Docket")
      expect(page).to have_content("AMA Direct Review")

      fill_in "ama_direct_review_docket_time_goals", with: "365"

    end
  end
end
