# frozen_string_literal: true

feature "BvaIntakeQueue", :all_dbs do
  context "Load BVA Intake Queue" do
    let(:organization) { BvaIntake.singleton }
    let(:bva_user) { User.authenticate!(roles: ["Admin Intake"]) }

    before do
      organization.add_user(bva_user)
      bva_user.reload
      visit "/organizations/#{organization.url}"
    end

    scenario "BVA Intake Queue Loads" do
      expect(find("h1")).to have_content("BVA Intake cases")
    end

    scenario "Has pending, ready for review, and completed tabs" do
      expect(page).to have_content "Pending"
      expect(page).to have_content "Ready for Review"
      expect(page).to have_content "Completed"
    end
  end
end
