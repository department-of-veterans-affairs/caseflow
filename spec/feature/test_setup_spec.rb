require "rails_helper"

RSpec.feature "Test Setup" do
  context "Access control" do
    scenario "non-Test User unable to access" do
      allow(Rails).to receive(:deploy_env?).with(:prod).and_return(false)
      User.authenticate!

      visit "test/setup"
      expect(page).to have_content("Unauthorized")
    end

    scenario "unable to acces in non-UAT environment" do
      allow(Rails).to receive(:deploy_env?).with(:prod).and_return(true)
      User.clear_stub!
      User.tester!

      visit "test/setup"
      expect(page).to have_content("Unauthorized")
    end
  end

  context "Data Reset" do
    before do
      ENV["TEST_APPEAL_IDS"].split(",").each_with_index do |appeal_id, i|
        appeal = Generators::Appeal.create(
          vacols_id: appeal_id,
          vbms_id: "#{appeal_id}_id"
        )
        task = EstablishClaim.create(appeal: appeal)
        task.prepare!

        appeal = Generators::Appeal.create(
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
      allow(Rails).to receive(:deploy_env?).with(:prod).and_return(false)

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
      allow(Rails).to receive(:deploy_env?).with(:prod).and_return(false)

      visit "test/setup"
      expect(page).to have_content("Uncertify Appeal")
      fill_in("UNCERTIFY_ME_vacols_id", with: "123C")
      expect(AppealRepository).to receive(:uncertify).with(Appeal.first)
      click_button("Uncertify Appeal")
    end

    scenario "Resets date and location for a Full Grant" do
      Generators::Appeal.create(
        vacols_id: "VACOLS123",
        vacols_record: :full_grant_decided
      )

      # this has to be repeated because mocks are not allowed in before clause
      allow(Rails).to receive(:deploy_env?).with(:prod).and_return(false)
      allow(ApplicationController).to receive(:dependencies_faked?).and_return(true)

      visit "test/setup"
      expect(page).to have_content("Reset Date and Location")
      fill_in("DISPATCH_ME_vacols_id", with: "VACOLS123")
      find(:xpath, "//label[@for='DISPATCH_ME_decision_type_full_grant']").click
      expect(TestDataService).to receive(:prepare_claims_establishment!).with(vacols_id: "VACOLS123",
                                                                              cancel_eps: true,
                                                                              decision_type: :full)
      page.find(:xpath, "//label[@for='DISPATCH_ME_cancel_eps_yes']").click
      click_button("Reset Date and Location")
    end

    scenario "Resets date and location for a Partial Grant" do
      Generators::Appeal.create(
        vacols_id: "VACOLS321",
        vacols_record: :partial_grant_decided
      )

      # this has to be repeated because mocks are not allowed in before clause
      allow(Rails).to receive(:deploy_env?).with(:prod).and_return(false)
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
  end
end
