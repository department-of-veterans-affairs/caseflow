# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_importer.rb"
describe "Appeals with unrecognized appellants" do
  let!(:appeal1) { import_appeal("spec/records/unrecognized_appellants/appeal-75406.json") }
  # let!(:appeal2) { import_appeal("spec/records/unrecognized_appellants/appeal-113251.json") }
  # let!(:appeal3) { import_appeal("spec/records/unrecognized_appellants/appeal-160271.json") }
  # let!(:appeal4) { import_appeal("spec/records/unrecognized_appellants/appeal-164926.json") }

  context "when given a BvaDispatchTask that is blocked by a child engineering task" do
    it "no longer shows these appeals in the AppealsWithNoTasksOrAllTasksOnHoldQuery" do
      query_result = AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
      # below is the count before the engineerin task is created
      expect(query_result.count).to eq(1)

      # Need to explicitly add a nonadmin user to the bva organization or create_from_root_task will break because the assignee pool will be empty
      # binding.pry
      bva_dispatch = Organization.find_by(type: "BvaDispatch")
      bva_dispatch_non_admin = User.find_by(css_id: "CAMEADM1")
      bva_dispatch.add_user(bva_dispatch_non_admin)

      dispatch_task = BvaDispatchTask.create_from_root_task(appeal1.root_task)
      user_dispatch_task = appeal1.tasks.where(type: "BvaDispatchTask").where(assigned_to_type: "User").first
      eng_task = EngineeringTask.create!(parent: user_dispatch_task, status: Constants.TASK_STATUSES.assigned, appeal: appeal1)
      appeal1.reload.treee
      updated_query_result = AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
      expect(updated_query_result.count).to eq(0)
    end
  end

  def import_appeal(file_path)
    sji = SanitizedJsonImporter.from_file(file_path, verbosity: 6)
    sji.import
    sji.imported_records[Appeal.table_name].first
  end
end
