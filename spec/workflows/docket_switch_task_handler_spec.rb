# frozen_string_literal: true

describe DocketSwitchTaskHandler, :all_dbs do
  include QueueHelpers

  before do
    FeatureToggle.enable!(:docket_switch)
    cotb_org.add_user(cotb_attorney)
    cotb_org.add_user(cotb_non_attorney)
    create(:staff, :judge_role, sdomainid: judge.css_id)
    create_list(:user, 6).each { |u| colocated_org.add_user(u) }
  end
  after { FeatureToggle.disable!(:docket_switch) }

  let(:cotb_org) { ClerkOfTheBoard.singleton }
  let(:old_docket_stream) { create(:appeal, :evidence_submission_docket, :with_post_intake_tasks) }
  let(:new_docket_stream) { create(:appeal, :hearing_docket) }

  let(:cotb_attorney) { create(:user, :with_vacols_attorney_record, full_name: "Clark Bard") }
  let!(:cotb_non_attorney) { create(:user, full_name: "Aang Bender") }
  let(:judge) { create(:user, :with_vacols_judge_record, full_name: "Judge the First", css_id: "JUDGE_1") }

  let!(:docket_switch_task) do
    task_class_type = (disposition == "denied") ? "denied" : "granted"
    create("docket_switch_#{task_class_type}_task".to_sym, appeal: old_docket_stream, assigned_to: cotb_attorney, assigned_by: judge)
  end

  let(:docket_switch) do
    create(
      :docket_switch,
      disposition: disposition,
      old_docket_stream: old_docket_stream,
      new_docket_stream: new_docket_stream,
      granted_request_issue_ids: granted_request_issue_ids
    )
  end
  let(:disposition) { "granted" }
  let(:granted_request_issue_ids) { [] }
  let(:old_tasks) { [] }
  let(:new_admin_actions) do
    [
      { assigned_by: cotb_attorney, type: AojColocatedTask.name},
      { assigned_by: cotb_attorney, type: PoaClarificationColocatedTask.name }
    ]
  end

  let!(:request_issues) { 3.times { create(:request_issue, decision_review: old_docket_stream) } }
  let(:docket_switch_task_handler) do
    described_class.new(docket_switch: docket_switch, old_tasks: old_tasks, new_admin_actions: new_admin_actions)
  end

  let(:colocated_org) { Colocated.singleton }

  describe "#call" do
    subject { docket_switch_task_handler.call }

    context "When the disposition is granted" do
      before { docket_switch.reload.send(:copy_granted_request_issues!) }
      let(:disposition) { "granted" }

      it "Cancels the original appeal stream and creates tasks on new stream" do
        docket_task = old_docket_stream.reload.tasks.find { |task| task.type == "EvidenceSubmissionWindowTask" }

        expect(old_docket_stream).to be_active

        expect(docket_task).to be_open

        subject

        expect(old_docket_stream.reload.tasks.active).to be_empty
        expect(old_docket_stream).to_not be_active
        expect(docket_task.reload).to be_cancelled

        new_docket_task = new_docket_stream.reload.tasks.find { |task| task.type == "ScheduleHearingTask" }

        new_admin_action = new_docket_stream.tasks.find { |task| task.type == "AojColocatedTask" && task.assigned_to_type == "User" }

        expect(new_docket_task).to be_active
        expect(new_admin_action).to be_active
      end
    end

    context "When the disposition is partially_granted" do
      let(:disposition) { "partially_granted" }
      let(:granted_request_issue_ids) { [old_docket_stream.reload.request_issues.first.id] }

      it "Cancels old optional tasks but not docket tasks or the appeal stream" do
        docket_task = old_docket_stream.tasks.find { |task| task.type == "EvidenceSubmissionWindowTask" }

        expect(old_docket_stream).to be_active
        expect(docket_task).to be_open

        subject

        expect(old_docket_stream.reload).to be_active
        expect(old_docket_stream.tasks.active).not_to be_empty
        expect(docket_task.reload).to be_active
      end
    end
  end
end
