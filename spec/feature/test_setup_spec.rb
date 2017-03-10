require "rails_helper"

RSpec.feature "Test Setup" do
  # before do
  #  Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  # end
  # let(:test_appeal_id) { ENV["TEST_APPEAL_IDS"].split(",")[0] }
  # before do
  #  test_certification = Certification.create!(vacols_id: test_appeal_id)
  #  form8 = Form8.create!(certification_id: test_certification.id)
  #  form8.assign_attributes_from_appeal(test_certification.appeal)
  #  form8.save
  #  form8.save_pdf!
  # end

  # let(:certification) { Certification.find_or_create_by_vacols_id(test_appeal_id) }

  context "Access control" do
    scenario "non-Test User unable to access" do
      allow(Rails).to receive(:deploy_env?).with(:uat).and_return(true)
      User.authenticate!

      visit "test/setup"
      expect(page).to have_content("Unauthorized")
    end

    scenario "unable to acces in non-UAT environment" do
      allow(Rails).to receive(:deploy_env?).with(:uat).and_return(false)
      User.clear_stub!
      User.tester!

      visit "test/setup"
      expect(page).to have_content("500")
    end
  end

  context "Data Reset" do
    before do
      ENV["TEST_APPEAL_IDS"].split(",").each_with_index do |appeal_id, i|
        appeal = Appeal.create(
          vacols_id: appeal_id,
          vbms_id: "#{appeal_id}_id"
        )
        task = EstablishClaim.create(appeal: appeal)
        task.prepare!
        appeal = Appeal.create(
          vacols_id: "#{appeal_id}_#{i}",
          vbms_id: "#{appeal_id}_id#{i}"
        )
        task2 = EstablishClaim.create(appeal: appeal)
        task2.prepare!
      end
    end

    scenario "Deletes all tasks" do
      # this has to be repeated because mocks are not allowed in before clause
      allow(Rails).to receive(:deploy_env?).with(:uat).and_return(true)
      User.tester!

      visit "test/setup"
      expect(page).to have_content("Clear Data")
      expect(EstablishClaim.all).not_to be_empty
      expect(Appeal.all).not_to be_empty
      expect(Task.all).not_to be_empty
      click_link("Clear Data")

      expect(EstablishClaim.all).to be_empty
      expect(Appeal.all).to be_empty
      expect(Task.all).to be_empty
    end

    scenario "Uncertifies an Appeal" do
      # this has to be repeated because mocks are not allowed in before clause
      allow(Rails).to receive(:deploy_env?).with(:uat).and_return(true)
      User.tester!

      visit "test/setup"
      expect(page).to have_content("Uncertify Appeal")
      fill_in("UNCERTIFY_ME_vacols_id", with: "123C")
      expect(AppealRepository).to receive(:uncertify).with(Appeal.first)
      click_button("Uncertify Appeal")
    end

    scenario "Resets date and location for a Full Grant" do
      # this has to be repeated because mocks are not allowed in before clause
      allow(Rails).to receive(:deploy_env?).with(:uat).and_return(true)
      User.tester!

      visit "test/setup"
      expect(page).to have_content("Uncertify Appeal")
      fill_in("UNCERTIFY_ME_vacols_id", with: "123C")
      expect(AppealRepository).to receive(:uncertify).with(Appeal.first)
      click_button("Uncertify Appeal")
    end
  end
end
