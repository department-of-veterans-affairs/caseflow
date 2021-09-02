# frozen_string_literal: true

def wait_for_page_render
  # This find forces a wait for the page to render. Without it, a test asserting presence or absence of content
  # may pass whether the content is present or not!
  find("div", id: "caseTitleDetailsSubheader")
end

def select_task_ids_in_ui(task_ids)
  visit "/queue"
  visit "/queue/appeals/#{appeal.uuid}"
  wait_for_page_render

  click_on "+ Add Substitute"

  fill_in("substitutionDate", with: Time.zone.parse("2021-01-01"))
  find("label", text: "Bob Vance, Spouse").click
  click_on "Continue"

  # Uncomment this if you wish to use demo specific selections in the browser
  # binding.pry
  # appeal.treee

  task_ids.each do |task_id|
    find("div", class: "checkbox-wrapper-taskIds[#{task_id}]").find("label").click
  end
  click_on "Continue"
  click_on "Confirm"
  wait_for_page_render
end

# Since the appeal is imported from JSON, the IDs here are always the below values.
# Give them friendly names for easier access
TASKS = {
  distribution: 2_000_758_353,
  schedule_hearing: 2_000_758_355,
  assign_hearing_disposition: 2_001_178_199,
  address_verify: 2_001_143_838,
  transcription: 2_001_233_993,
  evidence_submission_window: 2_001_233_994,
  evidence_or_argument_mail: 2_001_578_851
}.freeze

note = "This test is only used to aid manual testing/demonstration."
RSpec.feature "CASEFLOW-1501 Substitute appellant behavior", :postgres, skip: note do
  describe "Substitute Appellant appeal creation" do
    before do
      FeatureToggle.enable!(:recognized_granted_substitution_after_dd)
      FeatureToggle.enable!(:hearings_substitution_death_dismissal)

      cob_user = create(:user, css_id: "COB_USER", station_id: "101")
      ClerkOfTheBoard.singleton.add_user(cob_user)
      OrganizationsUser.make_user_admin(cob_user, ClerkOfTheBoard.singleton)
      User.authenticate!(user: cob_user)
    end

    after do
      FeatureToggle.disable!(:recognized_granted_substitution_after_dd)
      FeatureToggle.disable!(:hearings_substitution_death_dismissal)
    end

    let!(:appeal) do
      sji = SanitizedJsonImporter.from_file(
        "db/seeds/sanitized_json/b5eba21a-9baf-41a3-ac1c-08470c2b79c4.json",
        verbosity: 0
      )
      sji.import
      sji.imported_records[Appeal.table_name].first
    end

    let(:new_appeal) do
      appellant_substitution = AppellantSubstitution.find_by(source_appeal_id: appeal.id)
      appellant_substitution.target_appeal
    end

    context "with an EvidenceSubmissionWindowTask selected" do
      before do
        select_task_ids_in_ui([TASKS[:evidence_submission_window]])
      end

      it "show a success message" do
        expect(page).to have_content("You have successfully added a substitute appellant")
      end

      it "prints the generated task tree" do
        new_appeal.treee
      end
    end

    context "with a ScheduleHearingTask selected" do
      before do
        select_task_ids_in_ui([TASKS[:schedule_hearing]])
      end

      it "prints a task tree" do
        new_appeal.treee
      end
    end

    context "with a HearingAdminActionVerifyAddressTask selected" do
      before do
        select_task_ids_in_ui([TASKS[:address_verify]])
      end

      it "creates a proper task tree" do
        new_appeal.treee

        sht = ScheduleHearingTask.find_by(appeal_id: new_appeal.id)
        expect(sht.status).to eq "on_hold"

        haavat = HearingAdminActionVerifyAddressTask.find_by(appeal_id: new_appeal.id)
        expect(haavat.status).to eq "assigned"
        expect(haavat.assigned_to.type).to eq "HearingsManagement"
      end
    end

    context "with an AssignHearingDispositionTask selected" do
      before do
        select_task_ids_in_ui([TASKS[:assign_hearing_disposition]])
      end

      it "prints a task tree" do
        new_appeal.treee
      end
    end

    context "with a TranscriptionTask selected" do
      before do
        select_task_ids_in_ui([TASKS[:transcription]])
      end

      it "prints a task tree" do
        new_appeal.treee
      end
    end

    context "with EvidenceSubmissionWindow and Transcription selected" do
      before do
        select_task_ids_in_ui([TASKS[:evidence_submission_window], TASKS[:transcription]])
      end

      it "prints a task tree" do
        new_appeal.treee
      end
    end

    context "with Verify Address and Schedule Hearing selected" do
      before do
        select_task_ids_in_ui([TASKS[:address_verify], TASKS[:schedule_hearing]])
      end

      it "prints a task tree" do
        new_appeal.treee
      end
    end
  end
end
