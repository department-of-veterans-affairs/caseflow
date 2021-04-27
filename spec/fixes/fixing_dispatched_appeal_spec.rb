# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_importer.rb"

describe "Fixing dispatched appeals" do
  # https://dsva.slack.com/archives/CJL810329/p1619450075282800
  # https://hackmd.io/eXLbNNefTYy1sBoU8xwZ8w?both
  # Target state: appeal has the original decision_document and 2 root-level BvaDispatchTasks
  # - BvaDispatchTask 979805 and 979806 completed at 2020-06-26 16:54:45 UTC
  # - BvaDispatchTask 1400906 and its children cancelled
  describe "dispatched appeal without decision document" do
    let!(:appeal) do
      sji = SanitizedJsonImporter.from_file("spec/records/appeal-no_decision_doc.json", verbosity: 0)
      sji.import
      sji.imported_records[Appeal.table_name].first
    end

    it "restores decision_document and fixes task tree" do
      appeal.reload.treee

      # 1. Create new root-level BvaDispatchTask
      parent_dispatch_task = BvaDispatchTask.create!(appeal: appeal,
                                                     assigned_to: BvaDispatch.singleton,
                                                     parent: appeal.root_task)
      parent_dispatch_task.children.delete_all

      # 2. Move open BvaDispatchTask (1400906) under newly created root-level BvaDispatchTask
      dispatch_task_id = 2_001_400_906
      BvaDispatchTask.find(dispatch_task_id).update!(parent: parent_dispatch_task)

      # 3. Mark the currently open BvaDispatchTask (1400906) as cancelled
      parent_dispatch_task.cancel_task_and_child_subtasks
      Task.find(2_001_402_014).cancelled! # changed from 'completed' status to avoid future confusion

      # 4. Edit the BvaDispatchTasks (979806) from the original dispatch of the appeal to status completed with
      # completed date 2020-06-26 16:54:45 UTC to match the original tree
      dispatched_date = DateTime.new(2020, 6, 26, 16, 54, 45)
      orig_dispatch_task_id = 2_000_979_806
      orig_dispatch_task = BvaDispatchTask.find(orig_dispatch_task_id)
      orig_dispatch_task.update!(status: Constants.TASK_STATUSES.completed,
                                 updated_at: dispatched_date,
                                 assigned_at: dispatched_date,
                                 started_at: dispatched_date,
                                 closed_at: dispatched_date)
      orig_dispatch_task.parent.update!(status: Constants.TASK_STATUSES.completed,
                                        updated_at: dispatched_date,
                                        closed_at: dispatched_date,
                                        placed_on_hold_at: dispatched_date)

      # Close out appeal
      appeal.root_task.completed!
      appeal.tasks.where(type: :TrackVeteranTask).map(&:completed!)

      # 5. Recreate and reattach the decision document to the appeal because it was sent to the Veteran
      # and no edits have been made
      params = {
        appeal_id: appeal.id,
        appeal_type: "Appeal",
        citation_number: "A20011064",
        decision_date: DateTime.new(2020, 6, 26),
        redacted_document_location: "\\vacohsm01.dva.va.gov\vaco_workgroups\BVA\archdata\arch2006\A20011064.txt",
        submitted_at: DateTime.new(2020, 6, 26, 16, 54, 45),
        attempted_at: DateTime.new(2020, 6, 26, 16, 54, 46),
        processed_at: DateTime.new(2020, 6, 26, 16, 55, 5),
        uploaded_to_vbms_at: DateTime.new(2020, 6, 26, 16, 54, 50),
        last_submitted_at: DateTime.new(2020, 6, 26, 16, 54, 45)
      }

      decision_doc = DecisionDocument.create!(params)
      expect(appeal.decision_document).to eq decision_doc

      appeal.reload.treee
    end
  end
end
