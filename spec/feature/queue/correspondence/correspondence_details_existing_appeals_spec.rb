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
      visit "/queue/correspondence/#{@correspondence.uuid}/intake"
      click_button("Continue")
      existing_appeal_radio_options[:yes].click
      using_wait_time(wait_time) do
        page.all(".checkbox-wrapper-1").find(".cf-form-checkbox").first.click
      end
      find("label", text: "Waive Evidence Window").click
      find_by_id("waiveReason").fill_in with: "test waive note"
      click_button("Continue")

      click_button("Submit")
      click_button("Confirm")
      using_wait_time(wait_time) do
        expect(page).to have_content("You have successfully submitted a correspondence record")
      end
      visit "/queue/correspondence/#{@correspondence.uuid}"
      click_dropdown(prompt: "Select an action", text: "Remove waive of evidence window")
      expect(page).to have_content("Confirm waive removal")
      expect(page).to have_content("Once confirmed, the waive evidence window will be removed.")
      click_button("Confirm")
      expect(page).to have_content("The waive evidence window request has been removed from the \"Evidence submission window\" task")
    end
  end
end
