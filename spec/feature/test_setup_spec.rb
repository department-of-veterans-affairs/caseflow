require "rails_helper"

RSpec.feature "Test Setup" do
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
    before(:each) do
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
      User.tester!
    end

    scenario "Deletes all tasks" do
      # this has to be repeated because mocks are not allowed in before clause
      allow(Rails).to receive(:deploy_env?).with(:uat).and_return(true)

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

    scenario "Uncertifies an appeal" do
      # this has to be repeated because mocks are not allowed in before clause
      allow(Rails).to receive(:deploy_env?).with(:uat).and_return(true)

      visit "test/setup"
      expect(page).to have_content("Uncertify Appeal")
      fill_in("UNCERTIFY_ME_vacols_id", with: "123C")
      expect(AppealRepository).to receive(:uncertify).with(Appeal.first)
      click_button("Uncertify Appeal")
    end

    scenario "Fails to uncertify an appeal" do
      # this has to be repeated because mocks are not allowed in before clause
      allow(Rails).to receive(:deploy_env?).with(:uat).and_return(true)

      visit "test/setup"
      expect(page).to have_content("Uncertify Appeal")
      fill_in("UNCERTIFY_ME_vacols_id", with: "DANK")
      click_button("Uncertify Appeal")
      expect(page).to have_content("uncertifiable")
    end

    scenario "Resets date and location for a Full Grant" do
      # this has to be repeated because mocks are not allowed in before clause
      allow(Rails).to receive(:deploy_env?).with(:uat).and_return(true)
      allow(ApplicationController).to receive(:dependencies_faked?).and_return(true)

      visit "test/setup"
      expect(page).to have_content("Reset Date and Location")
      fill_in("DISPATCH_ME_vacols_id", with: "VACOLS123")
      expect(TestDataService).to receive(:prepare_claims_establishment!).with(vacols_id: "VACOLS123",
                                                                              cancel_eps: true,
                                                                              decision_type: :full)
      page.find(:xpath, "//label[@for='DISPATCH_ME_cancel_eps_yes']").click
      click_button("Reset Date and Location")
    end

    scenario "Resets date and location for a Partial Grant" do
      # this has to be repeated because mocks are not allowed in before clause
      allow(Rails).to receive(:deploy_env?).with(:uat).and_return(true)
      allow(ApplicationController).to receive(:dependencies_faked?).and_return(true)

      visit "test/setup"
      expect(page).to have_content("Reset Date and Location")
      fill_in("DISPATCH_ME_vacols_id", with: "VACOLS321")
      expect(TestDataService).to receive(:prepare_claims_establishment!).with(vacols_id: "VACOLS321",
                                                                              cancel_eps: true,
                                                                              decision_type: :partial)
      page.find(:xpath, "//label[@for='DISPATCH_ME_cancel_eps_yes']").click
      click_button("Reset Date and Location")
    end

    scenario "Fails to reset date and location" do
      # this has to be repeated because mocks are not allowed in before clause
      allow(Rails).to receive(:deploy_env?).with(:uat).and_return(true)
      allow(ApplicationController).to receive(:dependencies_faked?).and_return(true)

      visit "test/setup"
      expect(page).to have_content("Reset Date and Location")
      fill_in("DISPATCH_ME_vacols_id", with: "DANK")
      page.find(:xpath, "//label[@for='DISPATCH_ME_cancel_eps_yes']").click
      click_button("Reset Date and Location")
      expect(page).to have_content("not a testable appeal")
    end
  end
end
