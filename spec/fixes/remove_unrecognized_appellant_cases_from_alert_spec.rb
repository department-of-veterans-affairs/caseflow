# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"
require "helpers/sanitized_json_importer.rb"

describe "Appeals with unrecognized appellants" do
  context "appeal1 has an engineering task added to it" do
    let!(:appeal1) { import_appeal("spec/records/unrecognized_appellants/appeal-75406.json") }
    it "no longer shows this appeal in the AppealsWithNoTasksOrAllTasksOnHoldQuery" do
      add_nonadmin_user_to_bva_organization

      query_result = AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
      # below is the count before the engineering task is created
      expect(query_result.count).to eq(1)

      BvaDispatchTask.create_from_root_task(appeal1.root_task)
      user_dispatch_task = appeal1.tasks.where(type: "BvaDispatchTask").where(assigned_to_type: "User").first
      EngineeringTask.create!(parent: user_dispatch_task, status: Constants.TASK_STATUSES.assigned, appeal: appeal1)
      appeal1.reload.treee
      updated_query_result = AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
      expect(updated_query_result.count).to eq(0)
    end
  end

  context "appeal2 has an engineering task added to it" do
    let!(:appeal2) { import_appeal("spec/records/unrecognized_appellants/appeal-113251.json") }
    it "no longer shows this appeal in the AppealsWithNoTasksOrAllTasksOnHoldQuery" do
      add_nonadmin_user_to_bva_organization

      query_result = AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
      # below is the count before the engineering task is created
      expect(query_result.count).to eq(1)

      BvaDispatchTask.create_from_root_task(appeal2.root_task)
      user_dispatch_task = appeal2.tasks.where(type: "BvaDispatchTask").where(assigned_to_type: "User").first
      EngineeringTask.create!(parent: user_dispatch_task, status: Constants.TASK_STATUSES.assigned, appeal: appeal2)
      appeal2.reload.treee
      updated_query_result = AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
      expect(updated_query_result.count).to eq(0)
    end
  end

  context "appeal3 has an engineering task added to it" do
    let!(:appeal3) { import_appeal("spec/records/unrecognized_appellants/appeal-160271.json") }
    it "no longer shows this appeal in the AppealsWithNoTasksOrAllTasksOnHoldQuery" do
      add_nonadmin_user_to_bva_organization

      query_result = AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
      # below is the count before the engineering task is created
      expect(query_result.count).to eq(1)

      BvaDispatchTask.create_from_root_task(appeal3.root_task)
      user_dispatch_task = appeal3.tasks.where(type: "BvaDispatchTask").where(assigned_to_type: "User").first
      EngineeringTask.create!(parent: user_dispatch_task, status: Constants.TASK_STATUSES.assigned, appeal: appeal3)
      appeal3.reload.treee
      updated_query_result = AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
      expect(updated_query_result.count).to eq(0)
    end
  end

  context "appeal4 has an engineering task added to it" do
    let!(:appeal4) { import_appeal("spec/records/unrecognized_appellants/appeal-164926.json") }
    it "no longer shows this appeal in the AppealsWithNoTasksOrAllTasksOnHoldQuery" do
      add_nonadmin_user_to_bva_organization

      query_result = AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
      # below is the count before the engineering task is created
      expect(query_result.count).to eq(1)

      BvaDispatchTask.create_from_root_task(appeal4.root_task)
      user_dispatch_task = appeal4.tasks.where(type: "BvaDispatchTask").where(assigned_to_type: "User").first
      EngineeringTask.create!(parent: user_dispatch_task, status: Constants.TASK_STATUSES.assigned, appeal: appeal4)
      appeal4.reload.treee
      updated_query_result = AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
      expect(updated_query_result.count).to eq(0)
    end
  end

  def import_appeal(file_path)
    sji = SanitizedJsonImporter.from_file(file_path, verbosity: 6)
    sji.import
    sji.imported_records[Appeal.table_name].first
  end

  # Need to explicitly add a nonadmin user to the bva organization
  # Otherwise, create_from_root_task will break because the assignee pool will be empty
  def add_nonadmin_user_to_bva_organization
    bva_dispatch = Organization.find_by(type: "BvaDispatch")
    bva_dispatch_non_admin = User.find_by(css_id: "CAMEADM1")
    bva_dispatch.add_user(bva_dispatch_non_admin)
  end
end
