# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_importer.rb"

describe "Appeals with unrecognized appellants" do
  context "when given a BvaDispatchTask that is blocked by a child engineering task" do
    let!(:appeal1) { import_appeal("spec/records/unrecognized_appellants/appeal-75406.json") }
    let!(:appeal2) { import_appeal("spec/records/unrecognized_appellants/appeal-113251.json") }
    let!(:appeal3) { import_appeal("spec/records/unrecognized_appellants/appeal-160271.json") }
    let!(:appeal4) { import_appeal("spec/records/unrecognized_appellants/appeal-164926.json") }

    it "no longer shows these appeals in the AppealsWithNoTasksOrAllTasksOnHoldQuery" do
      query_result = AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
      # below is the count before the task trees are updated
      expect(query_result.count).to eq(4)

      # create a bva dispatch task
      # block it with an in progress engineering task
      appeals = [appeal1, appeal2, appeal3, appeal4]
      appeals.each do |appeal|
        dispatch_task = BvaDispatchTask.create_from_root_task(appeal.root_task)
        EngineeringTask.create(parent: dispatch_task, status: Constants.TASK_STATUSES.in_progress)
      end
      # count is now zero
      updated_query_result = AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
      expect(updated_query_result.count).to eq(0)
    end
  end

  def import_appeal(file_path)
    sji = SanitizedJsonImporter.from_file(file_path, verbosity: 0)
    sji.import
    sji.imported_records[Appeal.table_name].first
  end
end
