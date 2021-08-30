# frozen_string_literal: true

feature "CamoQueue", :all_dbs do
  context "Load CAMO Queue" do
    let(:organization) { VhaCamo.singleton }
    let(:camo_user) { User.authenticate!(roles: ["Admin Intake"]) }

    before do
      organization.add_user(camo_user)
      camo_user.reload
      visit "/organizations/#{organization.url}"
    end

    scenario "CAMO Queue Loads" do
      expect(find("h1")).to have_content("VHA CAMO cases")
    end

    scenario "New intake button takes user to intake" do
      page.find("button.intake-button").click
      expect(page).to have_content "Welcome to Caseflow Intake!"
    end
  end
end
