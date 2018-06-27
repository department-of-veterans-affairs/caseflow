require "rails_helper"
# rubocop:disable Style/FormatString

RSpec.feature "AmaQueue" do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:queue_beaam_appeals)
  end
  after do
    FeatureToggle.disable!(:queue_beaam_appeals)
  end

  let!(:attorney_user) do
    User.authenticate!(roles: ["System Admin"])
  end

  context "loads appellant detail view" do
    let!(:appeals) do
      [
        create(
          :appeal,
          veteran: create(:veteran, bgs_veteran_record: { first_name: "Pal" }),
          documents: create_list(:document, 5),
          request_issues: build_list(:request_issue, 3, description: "Knee pain")
        ),
        create(
          :appeal,
          veteran: create(:veteran),
          documents: create_list(:document, 4),
          request_issues: build_list(:request_issue, 2, description: "PTSD")
        ),
        create(
          :appeal,
          :appellant_not_veteran,
          veteran: create(:veteran),
          documents: create_list(:document, 3),
          request_issues: build_list(:request_issue, 1, description: "Tinnitus")
        )
      ]
    end

    scenario "veteran is the appellant" do
      visit "/queue/beaam"

      click_on appeals.first.veteran.first_name

      expect(page).to have_content("Veteran Details")
      expect(page).to have_content("The veteran is the appellant.")

      expect(page).to have_content(appeals.first.request_issues.first.description)
      expect(page).to have_content(appeals.first.docket_number)

      expect(page).to have_content("View #{appeals.first.documents.count} documents")
    end
  end
end