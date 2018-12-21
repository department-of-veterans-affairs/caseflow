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

    let(:veteran) { create(:veteran) }
    let(:hlr) { create(:higher_level_review, veteran_file_number: veteran.file_number) }
    let!(:in_progress_tasks) do
      [
        create(:higher_level_review_task, :in_progress, appeal: hlr, assigned_to: non_comp_org),
        create(:higher_level_review_task, :in_progress, appeal: hlr, assigned_to: non_comp_org)
      ]
    end

    let!(:completed_tasks) do
      [
        create(:higher_level_review_task, :completed, appeal: hlr, assigned_to: non_comp_org),
        create(:higher_level_review_task, :completed, appeal: hlr, assigned_to: non_comp_org)
      ]
    end

    before do
      User.stub = user
      OrganizationsUser.add_user_to_organization(user, non_comp_org)
    end

    scenario "displays tasks page" do
      visit "decision_reviews/nco"

      expect(page).to have_content("Non-Comp Org")
      expect(page).to have_content("In progress tasks")
      expect(page).to have_content("Completed tasks")

      # default is the in progress page
      expect(page).to have_content("Higher-Level Review", count: 2)
      click_on "Completed tasks"
      expect(page).to have_content("Higher-Level Review", count: 2)
    end
  end
end
