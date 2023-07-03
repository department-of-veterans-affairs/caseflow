# frozen_string_literal: true

describe IssuesUpdateTask do
  let(:user) { create(:user) }
  let(:bva_intake) { BvaIntake.singleton }
  let(:root_task) { create(:root_task) }
  let(:distribution_task) { create(:distribution_task, parent: root_task) }
  let(:task_class) { IssuesUpdateTask }

  before do
    bva_intake.add_user(user)
    User.authenticate!(user: user)
    FeatureToggle.enable!(:mst_identification)
    FeatureToggle.enable!(:pact_identification)
    FeatureToggle.enable!(:legacy_mst_pact_identification)
  end

  describe ".verify_user_can_create" do
    let(:params) { { appeal: root_task.appeal, parent_id: distribution_task&.id, type: task_class.name } }

    context "when no root task exists for appeal" do
      let(:distribution_task) { nil }

      it "throws an error" do
        expect { task_class.create!(
          appeal: root_task.appeal,
          parent_id: distribution_task&.id,
          type: task_class.name,
          assigned_to: bva_intake,
          assigned_by: user) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "proper params are sent" do
      it "creates the new task" do
        expect { task_class.create!(
          appeal: root_task.appeal,
          parent_id: distribution_task&.id,
          type: task_class.name,
          assigned_to: bva_intake,
          assigned_by: user) }.to change{IssuesUpdateTask.count}.by(1)
      end
    end

    # test contexts for successfully creating task when an appeal has a CC will go here once other tasks are made
  end

  describe ".format_instructions" do
    let(:issues_update_task) do
      task_class.create!(
        appeal: root_task.appeal,
        parent_id: distribution_task&.id,
        type: task_class.name,
        assigned_to: bva_intake,
        assigned_by: user
      )
    end

    # clear the instructions after each run
    after do
      issues_update_task.instructions.clear
      issues_update_task.save!
    end

    # Note: MST/PACT edit reasons are removed on release and commented out in case they are needed in the future
    context "changes occur to the MST status on an issue" do
      let(:params) do
        {
          change_type: "test change",
          issue_category: "test category",
          benefit_type: "test benefit",
          original_mst: false,
          original_pact: false,
          edit_mst: true,
          edit_pact: false
          # edit_reason: "reason for edit here...",
          # _mst_edit_reason: "MST reason here",
          # _pact_edit_reason: "PACT reason here"
        }
      end

      subject do
        issues_update_task.format_instructions(
          params[:change_type],
          params[:issue_category],
          params[:benefit_type],
          params[:original_mst],
          params[:original_pact],
          params[:edit_mst],
          params[:edit_pact]
          # params[:_mst_edit_reason],
          # params[:_pact_edit_reason]
        )
        issues_update_task
      end

      it "formats the instructions with MST" do
        expect(subject.instructions[0][0]).to eql("test change")
        expect(subject.instructions[0][1]).to eql("test benefit")
        expect(subject.instructions[0][2]).to eql("test category")
        expect(subject.instructions[0][3]).to eql("Special Issues: None")
        expect(subject.instructions[0][4]).to eql("Special Issues: MST")
        # expect(issues_update_task.instructions[0][5]).to eql("MST reason here")
        # expect(issues_update_task.instructions[0][6]).to eql("PACT reason here")
      end
    end

    context "changes occur to the PACT status on an issue" do
      let(:params) do
        {
          change_type: "test change",
          issue_category: "test category",
          benefit_type: "test benefit",
          original_mst: false,
          original_pact: false,
          edit_mst: false,
          edit_pact: true
          # mst_reason: "MST reason here",
          # pact_reason: "PACT reason here"
        }
      end

      subject do
        issues_update_task.format_instructions(
          params[:change_type],
          params[:issue_category],
          params[:benefit_type],
          params[:original_mst],
          params[:original_pact],
          params[:edit_mst],
          params[:edit_pact]
          # params[:mst_reason],
          # params[:pact_reason]
        )
        issues_update_task
      end

      it "formats the instructions with PACT" do
        expect(subject.instructions[0][0]).to eql("test change")
        expect(subject.instructions[0][1]).to eql("test benefit")
        expect(subject.instructions[0][2]).to eql("test category")
        expect(subject.instructions[0][3]).to eql("Special Issues: None")
        expect(subject.instructions[0][4]).to eql("Special Issues: PACT")
        # expect(issues_update_task.instructions[0][5]).to eql("MST reason here")
        # expect(issues_update_task.instructions[0][6]).to eql("PACT reason here")
      end
    end

    context "changes occur to the MST and PACT status on an issue" do
      let(:params) do
        {
          change_type: "test change",
          issue_category: "test category",
          benefit_type: "test benefit",
          original_mst: false,
          original_pact: false,
          edit_mst: true,
          edit_pact: true
          # mst_reason: "MST reason here",
          # pact_reason: "PACT reason here"
        }-
      end

      subject do
        issues_update_task.format_instructions(
          params[:change_type],
          params[:issue_category],
          params[:benefit_type],
          params[:original_mst],
          params[:original_pact],
          params[:edit_mst],
          params[:edit_pact]
          # params[:mst_reason],
          # params[:pact_reason]
        )
        issues_update_task
      end

      it "formats the instructions with MST and PACT" do
        expect(subject.instructions[0][0]).to eql("test change")
        expect(subject.instructions[0][1]).to eql("test benefit")
        expect(subject.instructions[0][2]).to eql("test category")
        expect(subject.instructions[0][3]).to eql("Special Issues: None")
        expect(subject.instructions[0][4]).to eql("Special Issues: MST, PACT")
        # expect(issues_update_task.instructions[0][5]).to eql("MST reason here")
        # expect(issues_update_task.instructions[0][6]).to eql("PACT reason here")
      end
    end

    context "MST and PACT status on an issue are removed" do
      let(:params) do
        {
          change_type: "test change",
          issue_category: "test category",
          benefit_type: "test benefit",
          original_mst: true,
          original_pact: true,
          edit_mst: false,
          edit_pact: false,
          # mst_reason: "MST reason here",
          # pact_reason: "PACT reason here"
        }
      end

      subject do
        issues_update_task.format_instructions(
          params[:change_type],
          params[:issue_category],
          params[:benefit_type],
          params[:original_mst],
          params[:original_pact],
          params[:edit_mst],
          params[:edit_pact]
          # params[:mst_reason],
          # params[:pact_reason]
        )
        issues_update_task
      end

      it "formats the instructions from MST and PACT to None" do
        expect(subject.instructions[0][0]).to eql("test change")
        expect(subject.instructions[0][1]).to eql("test benefit")
        expect(subject.instructions[0][2]).to eql("test category")
        expect(subject.instructions[0][3]).to eql("Special Issues: MST, PACT")
        expect(subject.instructions[0][4]).to eql("Special Issues: None")
        # expect(issues_update_task.instructions[0][4]).to eql("MST reason here")
        # expect(issues_update_task.instructions[0][5]).to eql("PACT reason here")
      end
    end
  end
end
