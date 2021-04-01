# frozen_string_literal: true

describe MdrTask, :postgres do
  require_relative "task_shared_examples.rb"
  let(:org_admin) { create(:user) { |u| OrganizationsUser.make_user_admin(u, CavcLitigationSupport.singleton) } }
  let(:org_nonadmin) { create(:user) { |u| CavcLitigationSupport.singleton.add_user(u) } }
  let(:other_user) { create(:user) }

  let(:created_by) { create(:user) }
  let(:updated_by) { create(:user) }
  let(:source_appeal) { create(:appeal) }
  let(:cavc_docket_number) { "123-1234567" }
  let(:represented_by_attorney) { true }
  let(:cavc_judge_full_name) { Constants::CAVC_JUDGE_FULL_NAMES.first }
  let(:cavc_decision_type) { Constants::CAVC_DECISION_TYPES.keys.first }
  let(:remand_subtype) { Constants::CAVC_REMAND_SUBTYPES.keys.first }
  let(:decision_date) { 5.days.ago.to_date }
  let(:judgement_date) { 4.days.ago.to_date }
  let(:mandate_date) { 3.days.ago.to_date }
  let(:decision_issues) do
    create_list(
      :decision_issue,
      3,
      :rating,
      decision_review: source_appeal,
      disposition: "denied",
      description: "Decision issue description",
      decision_text: "decision issue"
    )
  end
  let(:decision_issue_ids) { decision_issues.map(&:id) }
  let(:federal_circuit) { nil }
  let(:instructions) { "Instructions!" }

  let(:params) do
    {
      created_by: created_by,
      updated_by: updated_by,
      source_appeal: source_appeal,
      cavc_docket_number: cavc_docket_number,
      represented_by_attorney: represented_by_attorney,
      cavc_judge_full_name: cavc_judge_full_name,
      cavc_decision_type: cavc_decision_type,
      remand_subtype: remand_subtype,
      decision_date: decision_date,
      judgement_date: judgement_date,
      mandate_date: mandate_date,
      decision_issue_ids: decision_issue_ids,
      federal_circuit: federal_circuit,
      instructions: instructions
    }
  end
  let(:cavc_remand) { CavcRemand.create!(params) }
  let(:appeal) { cavc_remand.remand_appeal }

  describe ".create" do
    subject { described_class.create(parent: parent_task, appeal: appeal) }
    let!(:parent_task) { create(:cavc_task, appeal: appeal) }
    let(:parent_task_class) { CavcTask }

    it_behaves_like "task requiring specific parent"

    it "has expected default values" do
      new_task = subject
      expect(new_task.assigned_to).to eq CavcLitigationSupport.singleton
      expect(new_task.label).to eq COPY::MDR_TASK_LABEL
      expect(new_task.default_instructions).to eq [COPY::MDR_WINDOW_TASK_DEFAULT_INSTRUCTIONS]
    end

    describe ".create_with_hold" do
      subject { described_class.create_with_hold(parent_task) }

      it "creates task with child TimedHoldTask" do
        new_task = subject
        expect(new_task.valid?)
        expect(new_task.assigned_to).to eq CavcLitigationSupport.singleton
        expect(new_task.status).to eq Constants.TASK_STATUSES.on_hold

        expect(appeal.tasks).to include new_task
        expect(parent_task.children).to include new_task
        child_timed_hold_tasks = new_task.children.where(type: :TimedHoldTask)
        expect(child_timed_hold_tasks.count).to eq 1
        expect(child_timed_hold_tasks.first.assigned_to).to eq CavcLitigationSupport.singleton
        expect(child_timed_hold_tasks.first.status).to eq Constants.TASK_STATUSES.assigned
        expect(child_timed_hold_tasks.first.timer_end_time.to_date).to eq(decision_date + 90.days)

        expect(new_task.label).to eq COPY::MDR_TASK_LABEL
        expect(new_task.default_instructions).to eq [COPY::MDR_WINDOW_TASK_DEFAULT_INSTRUCTIONS]
      end
    end
  end

  describe "#available_actions" do
    let(:cavc_task) { create(:cavc_task, appeal: appeal) }
    let!(:mdr_task) { described_class.create_with_hold(cavc_task) }

    context "immediately after MdrTask is created" do
      it "returns available actions when MdrTask is on hold" do
        expect(mdr_task.reload.status).to eq Constants.TASK_STATUSES.on_hold
        child_timed_hold_tasks = mdr_task.children.where(type: :TimedHoldTask)
        expect(child_timed_hold_tasks.first.status).to eq Constants.TASK_STATUSES.assigned

        timed_hold = Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h
        expect(mdr_task.available_actions(org_admin)).to include timed_hold
        expect(mdr_task.available_actions(org_nonadmin)).to include timed_hold
        expect(mdr_task.available_actions(other_user)).to be_empty
      end
    end

    context "after more than 90 days have passed" do
      before do
        Timecop.travel(decision_date + 91.days)
        TaskTimerJob.perform_now
      end
      it "marks MdrTask as assigned" do
        expect(mdr_task.reload.status).to eq Constants.TASK_STATUSES.assigned
        child_timed_hold_tasks = mdr_task.children.where(type: :TimedHoldTask)
        expect(child_timed_hold_tasks.first.status).to eq Constants.TASK_STATUSES.completed
      end

      it "shows correct actions" do
        actions = [
          Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
          Constants.TASK_ACTIONS.CAVC_REMAND_RECEIVED_MDR.to_h
        ]

        expect(mdr_task.available_actions(org_admin)).to match_array(actions)
        expect(mdr_task.available_actions(org_nonadmin)).to match_array(actions)
        expect(mdr_task.available_actions(other_user)).to be_empty
      end
    end
  end
end
