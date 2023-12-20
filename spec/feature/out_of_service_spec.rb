# frozen_string_literal: true

RSpec.feature "Out of Service", :all_dbs do
  context "Across all apps" do
    before do
      User.authenticate!(css_id: "BVAAABSHIRE", roles: ["Admin Intake"])
    end

    after do
      Rails.cache.write("out_of_service", false)
      User.unauthenticate!
    end

    scenario "When out of service is disabled, it shows Caseflow Home page", :aggregate_failures do
      visit "/"
      expect(page).to have_current_path("/")
      expect(page).to have_content("BVAAABSHIRE (DSUSER)")
      expect(page).to have_link("Queue")
      expect(page).to have_content("Search case")
      expect(page).to have_content("Send feedback")
      expect(page.has_no_content?("Technical Difficulties")).to eq(true)
    end

    scenario "When out of service is enabled, it shows Out of service page" do
      Rails.cache.write("out_of_service", true)
      visit "/"
      expect(page).to have_content("Technical Difficulties")
    end
  end

  context "Certification" do
    before do
      FeatureToggle.enable!(:certification_v2)
    end

    after do
      Rails.cache.write("certification_out_of_service", false)
      FeatureToggle.disable!(:certification_v2)
    end

    let!(:current_user) { User.authenticate!(roles: ["Certify Appeal", "CertificationV2"]) }
    let(:nod) { Generators::Document.build(type: "NOD") }
    let(:soc) { Generators::Document.build(type: "SOC", received_at: Date.new(1987, 9, 6)) }
    let(:form9) { Generators::Document.build(type: "Form 9") }

    let(:documents) { [nod, soc, form9] }
    let(:appeal_ready) do
      create(:legacy_appeal, vacols_case: create(:case_with_form_9))
    end

    scenario "When out of service is disabled, it shows Check Documents page" do
      visit "certifications/new/#{appeal_ready.vacols_id}"
      expect(page).to have_content("Check Documents")
      expect(page).to_not have_content("Technical Difficulties")
    end

    scenario "When out of service is enabled, it shows Out of service page" do
      Rails.cache.write("certification_out_of_service", true)
      visit "certifications/new/#{appeal_ready.vacols_id}"
      expect(page).to have_content("Technical Difficulties")
    end
  end

  context "Reader" do
    before do
      Fakes::Initializer.load!
    end

    after do
      Rails.cache.write("reader_out_of_service", false)
    end
    let(:documents) { [] }

    let(:appeal) do
      create(:legacy_appeal, vacols_case: create(:case, documents: documents, case_issues: [create(:case_issue)]))
    end

    let!(:current_user) do
      User.authenticate!(roles: ["Reader"])
    end

    scenario "When out of service is disabled, it shows document page" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      expect(page).to have_content("Claims folder details")
      expect(page).to_not have_content("Technical Difficulties")
    end

    scenario "When out of service is enabled, it shows Out of service page" do
      Rails.cache.write("reader_out_of_service", true)
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      expect(page).to have_content("Technical Difficulties")
    end
  end

  context "Hearings" do
    after do
      Rails.cache.write("hearings_out_of_service", false)
    end

    let!(:current_user) do
      User.authenticate!(roles: ["Build HearSched"])
    end

    scenario "When out of service is disabled, it shows hearings page" do
      visit "/hearings/schedule/build"
      expect(page).to have_content("Build Schedule")
      expect(page).to_not have_content("Technical Difficulties")
    end

    scenario "When out of service is enabled, it shows out of service page" do
      Rails.cache.write("hearings_out_of_service", true)
      visit "/hearings/schedule/build"
      expect(page).to have_content("Technical Difficulties")
      expect(page).to_not have_content("Build Schedule")
    end
  end

  context "Dispatch" do
    after do
      Rails.cache.write("dispatch_out_of_service", false)
    end

    let!(:current_user) { User.authenticate!(roles: ["Establish Claim", "Manage Claim Establishment"]) }

    let(:appeal) do
      Generators::LegacyAppeal.create(vacols_record: vacols_record, documents: documents)
    end

    let(:vacols_record) { :remand_decided }

    scenario "When out of service is disabled, it shows Work Assignments page" do
      visit "dispatch/establish-claim"
      expect(page).to have_content("Your Work Assignments")
      expect(page).to_not have_content("Technical Difficulties")
    end

    scenario "When out of service is enabled, it shows Out of service page" do
      Rails.cache.write("dispatch_out_of_service", true)
      visit "dispatch/establish-claim"
      expect(page).to have_content("Technical Difficulties")
    end
  end
end
