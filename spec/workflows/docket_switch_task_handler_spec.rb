# frozen_string_literal: true

describe DocketSwitch::TaskHandler, :all_dbs do
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
    create(
      "docket_switch_#{task_class_type}_task".to_sym,
      appeal: old_docket_stream,
      assigned_to: cotb_attorney,
      assigned_by: judge
    )
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
  let!(:old_docket_stream_tasks) do
    [
      create(:translation_task, appeal: old_docket_stream, parent: create(:translation_task, appeal: old_docket_stream, parent: old_docket_stream.root_task, assigned_to: translation_organization)),
      create(:foia_task, appeal: old_docket_stream, parent: create(:translation_task, parent: old_docket_stream.root_task, assigned_to: other_organization))
    ]
  end
  let!(:translation_organization) { Translation.singleton }
  let!(:other_organization) { Organization.create!(name: "Other organization", url: "other") }

  let(:selected_task_ids) { [old_docket_stream_tasks.first.id.to_s] }

  let(:new_admin_actions) do
    [
      { assigned_by: cotb_attorney, type: AojColocatedTask.name },
      { assigned_by: cotb_attorney, type: PoaClarificationColocatedTask.name }
    ]
  end

  let!(:request_issues) { 3.times { create(:request_issue, decision_review: old_docket_stream) } }
  let(:docket_switch_task_handler) do
    described_class.new(
      docket_switch: docket_switch,
      selected_task_ids: selected_task_ids,
      new_admin_actions: new_admin_actions
    )
  end

  let(:colocated_org) { Colocated.singleton }

  describe "#call" do
    subject { docket_switch_task_handler.call }

    before { docket_switch.reload.send(:copy_granted_request_issues!) }

    context "When the disposition is granted" do
      let(:disposition) { "granted" }

      it "Completes granted and ruling tasks" do
        ruling_task = old_docket_stream.tasks.find_by(type: "DocketSwitchRulingTask")
        granted_task = old_docket_stream.tasks.find_by(type: "DocketSwitchGrantedTask")

        expect(ruling_task).to be_open
        expect(granted_task).to be_open

        subject

        expect(ruling_task.reload).to be_completed
        expect(granted_task.reload).to be_completed
      end

      it "Cancels the original appeal stream and creates selected and docket-related tasks on new stream" do
        # evidence to hearing docketswitch
        docket_task = old_docket_stream.reload.tasks.find { |task| task.type == "EvidenceSubmissionWindowTask" }

        expect(old_docket_stream).to be_active

        expect(docket_task).to be_open

        subject

        expect(old_docket_stream.reload.tasks.active).to be_empty
        expect(old_docket_stream).to_not be_active
        expect(docket_task.reload).to be_cancelled

        new_docket_task = new_docket_stream.reload.tasks.find { |task| task.type == "ScheduleHearingTask" }
        persistent_task_copy = new_docket_stream.tasks.assigned_to_any_user.find_by(type: "TranslationTask")
        new_admin_action = new_docket_stream.tasks.find do |task|
          task.type == "AojColocatedTask" && task.assigned_to_type == "User"
        end

        expect(new_docket_task).to be_active
        expect(persistent_task_copy).to be_active
        expect(new_docket_stream.tasks.find { |task| task.type == "FoiaTask" }).to be nil
        expect(new_admin_action).to be_active
      end
    end

    context "When the disposition is partially_granted" do
      let(:disposition) { "partially_granted" }
      let(:granted_request_issue_ids) { [old_docket_stream.reload.request_issues.first.id] }

      it "Moves selected tasks and creates docket tasks for new stream, only remove indicated tasks from old stream" do
        docket_task = old_docket_stream.tasks.find { |task| task.type == "EvidenceSubmissionWindowTask" }

        expect(old_docket_stream).to be_active
        expect(docket_task).to be_open

        subject

        expect(old_docket_stream.reload).to be_active
        expect(old_docket_stream.tasks.active).not_to be_empty
        expect(docket_task.reload).to be_active

        new_docket_task = new_docket_stream.reload.tasks.find { |task| task.type == "ScheduleHearingTask" }
        persistent_task_copy = new_docket_stream.tasks.assigned_to_any_user.find_by(type: "TranslationTask")
        new_admin_action = new_docket_stream.tasks.find do |task|
          task.type == "AojColocatedTask" && task.assigned_to_type == "User"
        end

        expect(new_docket_task).to be_active
        expect(persistent_task_copy).to be_active
        removed_task = old_docket_stream_tasks.find { |task| !selected_task_ids.include?(task.id.to_s) }
        expect(new_docket_stream.tasks.find { |task| task.type == removed_task.type }).to be nil
        expect(new_admin_action).to be_active
      end
    end

    context "when disposition is denied" do
      let(:disposition) { "denied" }
      let(:granted_request_issue_ids) { nil }

      it "Completes denied and ruling tasks" do
        ruling_task = old_docket_stream.reload.tasks.find { |task| task.type == "DocketSwitchRulingTask" }
        denied_task = old_docket_stream.tasks.find_by(type: "DocketSwitchDeniedTask")

        expect(ruling_task).to be_open
        expect(denied_task).to be_open

        subject

        expect(ruling_task.reload).to be_completed
        expect(denied_task.reload).to be_completed
      end
    end
  end
end
