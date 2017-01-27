require "rails_helper"

RSpec.feature "Test Setup" do
  before do
    ENV["DEPLOY_ENV"] = "uat"
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  context "for certification" do
    let(:test_appeal_id) { ENV["TEST_APPEAL_ID"] }

    before do
      test_certification = Certification.create!(vacols_id: test_appeal_id)
      test_certification.form8.update_from_appeal(test_certification.appeal)
      test_certification.form8.save_pdf!
    end

    scenario "isn't allowed by a non-test user" do
      User.authenticate!

      visit "certifications/#{test_appeal_id}"
      click_on("Upload and certify")

      certification = Certification.find_or_create_by_vacols_id(test_appeal_id)
      expect(certification.reload.completed_at).to eq(Time.zone.now)
      expect(page).not_to have_content("Uncertify Appeal")
    end

    scenario "is allowed by a test user" do
      User.clear_stub!
      User.tester!

      visit "certifications/#{test_appeal_id}"
      click_on("Upload and certify")

      certification = Certification.find_or_create_by_vacols_id(test_appeal_id)
      expect(certification.reload.completed_at).to eq(Time.zone.now)
      expect(page).to have_content("Uncertify Appeal")
      click_link("Uncertify Appeal")
      expect(Certification.where(id: certification.id).count).to eq(0)
    end
  end

  context "for claims establishment" do
    let(:appeal) { Appeal.create(vacols_id: "VACOLS123", vbms_id: "VBMS123") }

    scenario "isn't allowed by a non-test user" do
      User.authenticate!(roles: ["Establish Claim"])

      visit "dispatch/establish-claim"
      expect(page).not_to have_content("Reset Claims Establishment Tasks")
    end

    scenario "is allowed by a non-test user" do
      user = User.tester!(roles: ["Establish Claim"])
      EstablishClaim.create(appeal: appeal, user: user).complete!(status: 0)

      visit "dispatch/establish-claim"
      expect(page).to_not have_content("No previous tasks")
      click_link("Reset Claims Establishment Tasks")
      expect(page).to have_content("No previous tasks")
    end
  end
end
