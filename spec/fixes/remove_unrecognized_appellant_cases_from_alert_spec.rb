# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_importer.rb"

describe "Appeals with unrecognized appellants" do
  shared_examples "appeal has an engineering task added to it" do |path|
    it "no longer shows this appeal in the AppealsWithNoTasksOrAllTasksOnHoldQuery" do
      sji = SanitizedJsonImporter.from_file(path, verbosity: 0)
      sji.import
      appeal = sji.imported_records[Appeal.table_name].first
      add_nonadmin_user_to_bva_organization

      query_result = AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
      # below is the count before the engineering task is created
      expect(query_result.count).to eq(1)
      BvaDispatchTask.create_from_root_task(appeal.root_task)
      user_dispatch_task = appeal.tasks.where(type: "BvaDispatchTask").where(assigned_to_type: "User").first
      engineering_task = EngineeringTask.create!(parent: user_dispatch_task, status: Constants.TASK_STATUSES.assigned,
                                                 appeal: appeal, instructions: ["This task is on hold while Caseflow "\
                                                "engineering devises a solution for appeals with unrecognized "\
                                                "appellants."])
      expect(engineering_task.instructions).to eq(["This task is on hold while Caseflow engineering devises a "\
        "solution for appeals with unrecognized appellants."])
      appeal.reload.treee
      updated_query_result = AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
      expect(updated_query_result.count).to eq(0)
    end
  end

  context "appeal with id 75406" do
    include_examples "appeal has an engineering task added to it",
                     "spec/records/unrecognized_appellants/appeal-75406.json"
  end

  context "appeal with id 113251" do
    include_examples "appeal has an engineering task added to it",
                     "spec/records/unrecognized_appellants/appeal-113251.json"
  end

  context "appeal with id 160271" do
    include_examples "appeal has an engineering task added to it",
                     "spec/records/unrecognized_appellants/appeal-160271.json"
  end

  context "appeal with id 164926" do
    include_examples "appeal has an engineering task added to it",
                     "spec/records/unrecognized_appellants/appeal-164926.json"
  end

  # Need to explicitly add a nonadmin user to the bva organization
  # Otherwise, create_from_root_task will break because the assignee pool will be empty
  def add_nonadmin_user_to_bva_organization
    bva_dispatch = Organization.find_by(type: "BvaDispatch")
    bva_dispatch_non_admin = User.find_by(css_id: "CAMEADM1")
    bva_dispatch.add_user(bva_dispatch_non_admin)
  end
end
