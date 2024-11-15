# frozen_string_literal: true

RSpec.feature("Tasks related to an existing Appeal - In Correspondence Details Page") do
  include CorrespondenceHelpers
  include CorrespondenceTaskHelpers

  let(:wait_time) { 30 }
  let(:current_user) { create(:user) }
  let(:current_super) { create(:inbound_ops_team_supervisor) }
  let!(:veteran) { create(:veteran, first_name: "John", last_name: "Testingman", file_number: "8675309") }
  let(:mock_doc_uploader) { instance_double(CorrespondenceDocumentsEfolderUploader) }

  context "user waives evidence submission window task on an appeal" do
    before do
      InboundOpsTeam.singleton.add_user(current_super)
      User.authenticate!(user: current_super)
      FeatureToggle.enable!(:correspondence_queue)
      @correspondence = create(
        :correspondence,
        :with_correspondence_intake_task,
        assigned_to: MailTeam.singleton,
        veteran_id: veteran.id,
        uuid: SecureRandom.uuid,
        va_date_of_receipt: Time.zone.local(2023, 1, 1)
      )
      allow(CorrespondenceDocumentsEfolderUploader).to receive(:new).and_return(mock_doc_uploader)
      allow(mock_doc_uploader).to receive(:upload_documents_to_claim_evidence).and_return(true)

      2.times do
        appeal = create(:appeal, :evidence_submission_docket, veteran: veteran)
        InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
      end
    end

    it "completes the evidence submission window task" do
      existing_apppeals_list(@correspondence)
      all(".plus-symbol")[1].click
      click_dropdown(prompt: "Select an action", text: "Remove waive of evidence window")
      expect(page).to have_content("Confirm waive removal")
      expect(page).to have_content("Once confirmed, the waive evidence window will be removed.")
      click_button("Confirm")
      all(".plus-symbol")[1].click
      expect(page).to have_content(
        "The waive evidence window request has been removed from the " \
        "\"Evidence submission window\" task", wait: 5
      )
    end

    it "validate return to queue modal confirm" do
      existing_apppeals_list(@correspondence)
      all(".plus-symbol")[0].click
      page.all(".cf-form-checkbox")[1].click
      find(".cf-btn-link", text: "Return to queue").click
      expect(page).to have_selector("#submit-correspondence-intake-modal", visible: true)
      expect(page).to have_content("Return to queue")
      within("#submit-correspondence-intake-modal") do
        click_button "Confirm"
      end
      expect(current_path).to eq("/queue/correspondence/team")
    end

    it "validate return to queue modal cancel" do
      existing_apppeals_list(@correspondence)
      all(".plus-symbol")[0].click
      page.all(".cf-form-checkbox")[1].click
      find(".cf-btn-link", text: "Return to queue").click
      expect(page).to have_selector("#submit-correspondence-intake-modal", visible: true)
      within("#submit-correspondence-intake-modal") do
        click_button "Cancel"
      end
      expect(page).not_to have_selector("#submit-correspondence-intake-modal", visible: false)
    end

    it "validating the Instructional text update on Linked Appeals Gray Table" do
      existing_apppeals_list(@correspondence)
      all(".plus-symbol")[0].click
      page.all(".cf-form-checkbox")[1].click
      expect(page).to have_content("The linked appeal must be saved before tasks can be added.")
      click_button "Save changes"
      using_wait_time(wait_time) do
        expect(page).to have_content("You have successfully saved changes to this page")
        expect(page).not_to have_content("The linked appeal must be saved before tasks can be added.")
      end
    end
  end

  context "user can add new tasks to linked appeal" do
    before do
      InboundOpsTeam.singleton.add_user(current_super)
      User.authenticate!(user: current_super)
      FeatureToggle.enable!(:correspondence_queue)
      @correspondence = create(
        :correspondence,
        :with_correspondence_intake_task,
        assigned_to: MailTeam.singleton,
        veteran_id: veteran.id,
        uuid: SecureRandom.uuid,
        va_date_of_receipt: Time.zone.local(2023, 1, 1)
      )
      allow(CorrespondenceDocumentsEfolderUploader).to receive(:new).and_return(mock_doc_uploader)
      allow(mock_doc_uploader).to receive(:upload_documents_to_claim_evidence).and_return(true)

      2.times do
        appeal = create(:appeal, :evidence_submission_docket, veteran: veteran)
        InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
      end
    end

    it "Adds a new task related to appeal on Correspondence Details page" do
      existing_apppeals_list(@correspondence)
      all(".plus-symbol")[1].click
      click_on(class: "usa-button-secondary tasks-added-button-spacing usa-button", wait: 5)
      expect(page).to have_content("Add task to appeal")
      expect(page).to have_selector(".add-task-modal-container")
      expect(page).to have_field("content")
      find(".add-task-dropdown-style").click
      find(".react-select__option", text: "Congressional Interest").click
      fill_in "content", with: "Test"
      click_button "Next"
      using_wait_time(10) do
        expect(page).to have_content("Congressional Interest")
      end
    end
  end
end
