# frozen_string_literal: true

describe DocketSwitchTaskHandler, :all_dbs do
  include QueueHelpers

  before do
    FeatureToggle.enable!(:docket_switch)
    cotb_org.add_user(cotb_attorney)
    cotb_org.add_user(cotb_non_attorney)
    create(:staff, :judge_role, sdomainid: judge.css_id)
  end
  after { FeatureToggle.disable!(:docket_switch) }

  let(:cotb_org) { ClerkOfTheBoard.singleton }
  let(:old_docket_stream) { create(:appeal, :evidence_submission_docket, :with_post_intake_tasks) }
  let(:new_docket_stream) { create(:appeal, :hearing_docket) }

  let(:root_task) { create(:root_task, :completed, appeal: appeal) }
  let(:cotb_attorney) { create(:user, :with_vacols_attorney_record, full_name: "Clark Bard") }
  let!(:cotb_non_attorney) { create(:user, full_name: "Aang Bender") }
  let(:judge) { create(:user, :with_vacols_judge_record, full_name: "Judge the First", css_id: "JUDGE_1") }

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
  let(:new_admin_actions) { [] }

  let!(:request_issues) { 3.times { create(:request_issue, decision_review: old_docket_stream) } }


  describe "#call" do
    subject { described_class.new(docket_switch: docket_switch, old_tasks: old_tasks, new_admin_actions: new_admin_actions).call }

    context "When the disposition is granted" do
      let(:disposition) { "granted" }

      it "Cancels the original appeal stream" do
        docket_task = old_docket_stream.tasks.find { |task| task.type == "EvidenceSubmissionWindowTask" }

        expect(old_docket_stream).to be_active
        expect(docket_task).to be_open

        subject

        expect(old_docket_stream).to_not be_active
        expect(old_docket_stream.tasks.active).to be_empty
        expect(docket_task.reload).to be_cancelled
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

        expect(old_docket_stream).to be_active
        expect(old_docket_stream.tasks.active).not_to be_empty
        expect(docket_task.reload).to be_active
      end
    end
  end
end
