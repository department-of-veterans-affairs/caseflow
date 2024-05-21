# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_importer.rb"
require "helpers/intake_renderer.rb"

##
# This RSpec replicates the "Unassigned" nomenclature in the "Assigned To" column of the search results.
#
# - [Dispatch Task #204](https://github.com/department-of-veterans-affairs/dsva-vacols/issues/204)

feature "Search results for AMA appeal" do
  before do
    User.authenticate!(css_id: "PETERSBVAM")
    Functions.grant!("System Admin", users: ["PETERSBVAM"]) # enable access to `export` endpoint
  end

  context "given undispatched appeal with no active tasks" do
    let(:appeal) do
      sji = SanitizedJsonImporter.from_file("spec/records/appeal-53008.json", verbosity: 0)
      sji.import
      sji.imported_records[Appeal.table_name].first
    end

    before do
      allow_any_instance_of(BGSService).to receive(:fetch_file_number_by_ssn)
        .with(appeal.veteran.ssn.to_s)
        .and_return(appeal.veteran.file_number)
    end

    it "creates tasks and other records associated with a dispatched appeal" do
      expect(BVAAppealStatus.new(tasks: appeal.tasks).status).to eq :unknown # We will fix this
      expect(appeal.root_task.status).to eq "on_hold"

      visit "/search?veteran_ids=#{appeal.veteran.id}"
      expect(page).to have_content("Unknown") # in the "Appellant Name" column
      expect(appeal.status.status).to eq :unknown
      expect(page).to have_content(COPY::CASE_LIST_TABLE_UNASSIGNED_LABEL) # in the "Assigned To" column
      expect(appeal.assigned_to_location).to eq COPY::CASE_LIST_TABLE_UNASSIGNED_LABEL

      # Code from Appeal#assigned_to_location
      tasks = appeal.tasks
      recently_updated_task = Task.any_recently_updated(
        tasks.active.visible_in_queue_table_view,
        tasks.on_hold.visible_in_queue_table_view
      )
      expect(recently_updated_task).to eq appeal.root_task
      expect(recently_updated_task.assigned_to_label).to eq COPY::CASE_LIST_TABLE_UNASSIGNED_LABEL

      org_dispatch_task = BvaDispatchTask.create_from_root_task(appeal.root_task)
      params = {
        appeal_id: appeal.external_id,
        citation_number: "12312312",
        decision_date: Time.zone.today.to_s,
        file: "longfilenamehere",
        redacted_document_location: "C://Windows/User/BVASWIFTT/Documents/NewDecision.docx"
      }
      visit "/search?veteran_ids=#{appeal.veteran.id}"
      expect(page).to have_content("Signed") # in the "Appellant Name" column
      expect(BVAAppealStatus.new(tasks: appeal.tasks).status).to eq :signed
      bva_dispatcher = org_dispatch_task.children.first.assigned_to
      expect(page).to have_content(bva_dispatcher.css_id) # in the "Assigned To" column
      expect(appeal.assigned_to_location).to eq bva_dispatcher.css_id

      BvaDispatchTask.outcode(appeal, params, bva_dispatcher)
      visit "/search?veteran_ids=#{appeal.veteran.id}"
      expect(page).to have_content("Dispatched") # in the "Appellant Name" column
      expect(BVAAppealStatus.new(tasks: appeal.tasks).status).to eq :dispatched
      expect(page).to have_content("Post-decision") # in the "Assigned To" column
      expect(appeal.assigned_to_location).to eq "Post-decision"
      expect(appeal.root_task.status).to eq "completed"
    end
  end

  context "appeal status is distributed to judge" do
    let!(:appeal) { create(:appeal, :assigned_to_judge) }
    let!(:default_user) { create(:default_user) }
    let!(:hearings_coordinator_user) do
      coordinator = create(:hearings_coordinator)
      HearingsManagement.singleton.add_user(coordinator)
      coordinator
    end
    let!(:attorney) do
      attorney = create(:user)
      create(:staff, :attorney_role, sdomainid: attorney.css_id)
      attorney
    end
    let!(:judge) do
      judge = create(:user)
      create(:staff, :judge_role, sdomainid: judge.css_id)
      judge
    end

    before do
      allow_any_instance_of(BGSService).to receive(:fetch_file_number_by_ssn)
        .with(appeal.veteran.ssn.to_s)
        .and_return(appeal.veteran.file_number)
    end
    context "user is not an attorney, judge, or hearing coordinator" do
      scenario "current user is a system admin" do
        visit "/search?veteran_ids=#{appeal.veteran.id}"
        expect(appeal.status.status).to eq :distributed_to_judge
        expect(appeal.assigned_to_location).to eq "BVAAABSHIRE" # css_id is part of assigned_to
        expect(page).not_to have_content("BVAAABSHIRE") # but css_id is not displayed in the page
      end

      scenario "current user is a default user" do
        User.authenticate!(user: default_user)
        visit "/search?veteran_ids=#{appeal.veteran.id}"
        expect(appeal.status.status).to eq :distributed_to_judge
        expect(appeal.assigned_to_location).to eq "BVAAABSHIRE" # css_id is part of assigned_to
        expect(page).not_to have_content("BVAAABSHIRE") # but css_id is not displayed in the page
      end
    end

    context "user is an attorney, a judge, or a hearing coordinator" do
      scenario "user is an attorney" do
        User.authenticate!(user: attorney)
        visit "/search?veteran_ids=#{appeal.veteran.id}"
        expect(appeal.status.status).to eq :distributed_to_judge
        expect(appeal.assigned_to_location).to eq "BVAAABSHIRE" # css_id is part of assigned_to
        expect(page).to have_content("BVAAABSHIRE") # and css_id is displayed in the page
      end

      scenario "user is an judge" do
        User.authenticate!(user: judge)
        visit "/search?veteran_ids=#{appeal.veteran.id}"
        expect(appeal.status.status).to eq :distributed_to_judge
        expect(appeal.assigned_to_location).to eq "BVAAABSHIRE" # css_id is part of assigned_to
        expect(page).to have_content("BVAAABSHIRE") # and css_id is displayed in the page
      end

      scenario "user is an hearings coordinator" do
        User.authenticate!(user: hearings_coordinator_user)
        visit "/search?veteran_ids=#{appeal.veteran.id}"
        expect(appeal.status.status).to eq :distributed_to_judge
        expect(appeal.assigned_to_location).to eq "BVAAABSHIRE" # css_id is part of assigned_to
        expect(page).to have_content("BVAAABSHIRE") # and css_id is displayed in the page
      end
    end
  end
end
