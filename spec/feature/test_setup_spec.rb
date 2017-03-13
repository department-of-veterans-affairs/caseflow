require "rails_helper"

RSpec.feature "Test Setup" do
  before do
    ENV["DEPLOY_ENV"] = "uat"
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  context "for certification" do
    let(:test_appeal_id) { ENV["TEST_APPEAL_IDS"].split(",")[0] }

    before do
      test_certification = Certification.create!(vacols_id: test_appeal_id)
      form8 = Form8.create!(certification_id: test_certification.id)
      form8.assign_attributes_from_appeal(test_certification.appeal)
      form8.save
      form8.save_pdf!
    end

    let(:certification) { Certification.find_or_create_by_vacols_id(test_appeal_id) }

    scenario "isn't allowed by a non-test user" do
      User.authenticate!

      visit "certifications/#{test_appeal_id}"
      click_on("Upload and certify")

      expect(certification.reload.completed_at).to eq(Time.zone.now)
      visit "test/setup"
      click_link("Uncertify Appeal #{test_appeal_id}")
      expect(Certification.where(id: certification.id).count).to eq(1)
    end

    scenario "is allowed by a test user" do
      User.clear_stub!
      User.tester!

      visit "certifications/#{test_appeal_id}"
      click_on("Upload and certify")

      expect(certification.reload.completed_at).to eq(Time.zone.now)
      visit "test/setup"
      expect(page).to have_content("Uncertify Appeal #{test_appeal_id}")
      click_link("Uncertify Appeal #{test_appeal_id}")
      expect(Certification.where(id: certification.id).count).to eq(0)
    end
  end

  context "for claims establishment" do
    let(:appeal) { Appeal.create(vacols_id: "VACOLS123", vbms_id: "FULLGRANT_VBMS_ID") }
    let(:user) { User.tester!(roles: ["Establish Claim"]) }

    scenario "isn't allowed by a non-test user" do
      Fakes::AppealRepository.records = {
        "VACOLS123" => Fakes::AppealRepository.appeal_full_grant_decided
      }
      User.authenticate!(roles: ["Establish Claim"])
      # Have to prepare tasks separately for each user, hence repeated code
      # Can be a Dispatch helper instead?
      task = EstablishClaim.create(appeal: appeal)
      task.prepare!
      task.assign!(:assigned, user)
      task.start!
      task.review!
      task.complete!(:completed, status: 0)

      visit "dispatch/establish-claim"
      expect(page).to have_content("FULLGRANT_VBMS_ID")
      visit "test/setup"
      click_link("Reset Claims Establishment Tasks")
      visit "dispatch/establish-claim"
      expect(page).to have_content("FULLGRANT_VBMS_ID")
    end

    scenario "is allowed by a test user" do
      Fakes::AppealRepository.records = {
        "VACOLS123" => Fakes::AppealRepository.appeal_full_grant_decided
      }
      task = EstablishClaim.create(appeal: appeal)
      task.prepare!
      task.assign!(:assigned, user)
      task.start!
      task.review!
      task.complete!(:completed, status: 0)

      visit "dispatch/establish-claim"
      expect(page).to have_content("FULLGRANT_VBMS_ID")
      visit "test/setup"
      click_link("Reset Claims Establishment Tasks")
      visit "dispatch/establish-claim"
      expect(page).to have_content("There are no more claims in your queue")
    end
  end
end
