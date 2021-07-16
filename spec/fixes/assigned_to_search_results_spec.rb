# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_importer.rb"
require "helpers/intake_renderer.rb"

##
# This RSpec replicates the "Case Storage" nomenclature in the "Assigned To" column of the search results.
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

    it "creates tasks and other records associated with a dispatched appeal" do
      expect(BVAAppealStatus.new(appeal: appeal).status).to eq :unknown # We will fix this
      expect(appeal.root_task.status).to eq "on_hold"

      visit "/search?veteran_ids=#{appeal.veteran.id}"
      expect(page).to have_content("Unknown") # in the "Appellant Name" column
      expect(appeal.status.status).to eq :unknown
      expect(page).to have_content("Case storage") # in the "Assigned To" column
      expect(appeal.assigned_to_location).to eq "Case storage"

      # Code from Appeal#assigned_to_location
      tasks = appeal.tasks
      recently_updated_task = Task.any_recently_updated(
        tasks.active.visible_in_queue_table_view,
        tasks.on_hold.visible_in_queue_table_view
      )
      expect(recently_updated_task).to eq appeal.root_task
      expect(recently_updated_task.assigned_to_label).to eq "Case storage"

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
      expect(BVAAppealStatus.new(appeal: appeal).status).to eq :signed
      bva_dispatcher = org_dispatch_task.children.first.assigned_to
      expect(page).to have_content(bva_dispatcher.css_id) # in the "Assigned To" column
      expect(appeal.assigned_to_location).to eq bva_dispatcher.css_id

      BvaDispatchTask.outcode(appeal, params, bva_dispatcher)
      visit "/search?veteran_ids=#{appeal.veteran.id}"
      expect(page).to have_content("Dispatched") # in the "Appellant Name" column
      expect(BVAAppealStatus.new(appeal: appeal).status).to eq :dispatched
      expect(page).to have_content("Post-decision") # in the "Assigned To" column
      expect(appeal.assigned_to_location).to eq "Post-decision"
      expect(appeal.root_task.status).to eq "completed"
    end
  end
end
