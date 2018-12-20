require "rails_helper"

RSpec.feature "NonComp Queue" do
  before do
    FeatureToggle.enable!(:decision_reviews)
  end

  after do
    FeatureToggle.disable!(:decision_reviews)
  end

  context "with an existing organization" do
    let!(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
    let(:user) { create(:default_user) }

    before do
      User.stub = user
      OrganizationsUser.add_user_to_organization(user, non_comp_org)
    end

    scenario "displays tasks page" do
      visit "decision_reviews/nco"

      expect(page).to have_content("Non-Comp Org")
      expect(page).to have_content("In progress tasks")
      expect(page).to have_content("Completed tasks")
    end
  end
end
