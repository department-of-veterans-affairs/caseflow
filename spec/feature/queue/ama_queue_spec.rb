require "rails_helper"

RSpec.feature "AmaQueue" do
  before do
    Time.zone = "America/New_York"

    Fakes::Initializer.load!
    FeatureToggle.enable!(:queue_beaam_appeals)
    FeatureToggle.enable!(:test_facols)
  end
  after do
    FeatureToggle.disable!(:test_facols)
    FeatureToggle.disable!(:queue_beaam_appeals)
  end

  let(:attorney_first_name) { "Robby" }
  let(:attorney_last_name) { "McDobby" }
  let!(:attorney_user) do
    FactoryBot.create(:user, roles: ["Reader"], full_name: "#{attorney_first_name} #{attorney_last_name}")
  end
  let!(:vacols_atty) do
    FactoryBot.create(
      :staff,
      :attorney_role,
      sdomainid: attorney_user.css_id,
      snamef: attorney_first_name,
      snamel: attorney_last_name
    )
  end

  let!(:user) do
    User.authenticate!(user: attorney_user)
  end

  context "loads appellant detail view" do
    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:default_power_of_attorney_record).and_return(
        file_number: "633792224",
        power_of_attorney:
          {
            legacy_poa_cd: "3QQ",
            nm: poa_name,
            org_type_nm: "POA Attorney",
            ptcpnt_id: "600153863"
          },
        ptcpnt_id: "600085544"
      )
    end

    let(:poa_name) { "Test POA" }

    let!(:appeals) do
      [
        create(
          :appeal,
          advanced_on_docket: true,
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

      expect(page).to have_content("About the Veteran")

      expect(page).to have_content("AOD")

      expect(page).to have_content(appeals.first.request_issues.first.description)
      expect(page).to have_content(appeals.first.docket_number)
      expect(page).to have_content(poa_name)

      expect(page).to have_content("View Veteran's documents")
      expect(page).to have_selector("text", id: "NEW")
      expect(page).to have_content("5 docs")

      click_on "View Veteran's documents"
      expect(page).to have_content("Claims Folder")

      visit "/queue/beaam"
      click_on appeals.first.veteran.first_name

      expect(page).not_to have_selector("text", id: "NEW")
    end
  end
end
