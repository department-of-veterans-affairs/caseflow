# frozen_string_literal: true

RSpec.describe DocketSwitch, type: :model do
  let(:cotb_team) { ClerkOfTheBoard.singleton }
  let(:judge) { create(:user, full_name: "Judge User", css_id: "JUDGE_1") }
  let(:attorney) { create(:user) }
  let!(:judge_team) do
    JudgeTeam.create_for_judge(judge).tap { |jt| jt.add_user(attorney) }
  end
  let(:cotb_user) { create(:user, full_name: "Clerk Atty") }
  let(:appeal) do
    create(
      :appeal,
      request_issues: build_list(
        :request_issue, 3
      )
    )
  end
  let(:new_docket_stream) { appeal.create_stream(:switched_docket) }
  let(:docket_switch_task) do
    task_class_type = (disposition == "denied") ? "denied" : "granted"
    create("docket_switch_#{task_class_type}_task".to_sym, appeal: appeal, assigned_to: cotb_user, assigned_by: judge)
  end
  let(:disposition) { nil }
  let(:assigned_to_id) { nil }
  let(:granted_request_issue_ids) { appeal.request_issues.map(&:id) }
  let(:docket_switch) do
    create(
      :docket_switch,
      old_docket_stream: appeal,
      task: docket_switch_task,
      disposition: disposition,
      granted_request_issue_ids: granted_request_issue_ids
    )
  end

  before do
    create(:staff, :attorney_role, sdomainid: cotb_user.css_id)
    create(:staff, :judge_role, sdomainid: judge.reload.css_id)
    cotb_team.add_user(cotb_user)
  end

  context "#process!" do
    subject { docket_switch.process! }

    context "disposition is denied" do
      let(:disposition) { "denied" }

      it "closes the DocketSwitchDeniedTask" do
        expect(docket_switch_task).to be_assigned

        subject

        expect(docket_switch_task).to be_completed
      end
    end

    context "disposition is granted or partially granted" do
      context "when disposition is granted (full grant)" do
        let(:disposition) { "granted" }
        let(:granted_request_issue_ids) { nil }

        it "moves all request issues to a new appeal stream and marks the original appeal as docket switched" do
          expect(docket_switch_task).to be_assigned

          subject

          # new stream has a the new docket type
          expect(docket_switch.new_docket_stream.docket_type).to eq(docket_switch.docket_type)

          # all request issues are copied to new appeal stream, accessible as new_docket_stream
          expect(docket_switch.new_docket_stream.request_issues.count).to eq appeal.request_issues.count

          # all old request issues closed
          expect(appeal.request_issues.map { |ri| ri.reload.closed_status }.uniq).to eq ["docket_switch"]

          # Docket switch task gets completed
          expect(docket_switch_task).to be_completed

          # Appeal Status API shows original stream's status of docket switched
          expect(appeal.status.to_sym).to eq :docket_switched

          # Docket switch task has been copied to new appeal stream
          new_completed_task = DocketSwitchGrantedTask.find_by(appeal: docket_switch.new_docket_stream)
          expect(new_completed_task).to_not be_nil
          expect(new_completed_task).to be_completed
        end
      end

      context "when disposition is partially_granted" do
        let(:disposition) { "partially_granted" }
        let(:granted_request_issue_ids) { appeal.request_issues[0..1].map(&:id) }

        it "moves granted issues to new appeal stream and maintains original stream" do
          expect(docket_switch_task).to be_assigned

          subject

          # new stream has a the new docket type
          expect(docket_switch.new_docket_stream.docket_type).to eq(docket_switch.docket_type)

          # granted request issues are copied to new appeal stream
          expect(docket_switch.new_docket_stream.request_issues.count).to eq 2

          # granted old request issues closed
          expect(appeal.request_issues.map { |ri| ri.reload.closed_status }.compact.uniq).to eq ["docket_switch"]
          expect(appeal.request_issues.active.count).to eq 1

          # Docket switch task gets completed
          expect(docket_switch_task).to be_completed

          # Docket switch task has been copied to new appeal stream
          new_completed_task = DocketSwitchGrantedTask.assigned_to_any_user.find_by(
            appeal: docket_switch.new_docket_stream
          )
          expect(new_completed_task).to_not be_nil
          expect(new_completed_task).to be_completed

          # To do: Check for correct appeal status after task handling logic is implemented
        end
      end
    end
  end

  context "#valid?" do
    subject do
      build(
        :docket_switch,
        old_docket_stream: appeal,
        task: docket_switch_task,
        disposition: disposition,
        granted_request_issue_ids: granted_request_issue_ids
      )
    end

    context "when partially granted" do
      let(:disposition) { "partially_granted" }

      context "when issue ids not set" do
        let(:granted_request_issue_ids) { nil }

        it "not be valid" do
          expect(subject).not_to be_valid
        end
      end
    end

    context "when not partial grant" do
      let(:disposition) { "denied" }

      it "validates without " do
        expect(subject).to be_valid
      end
    end
  end
end
