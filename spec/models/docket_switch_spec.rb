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
  let(:granted_docket_switch_task) { create(:docket_switch_granted_task, appeal: appeal, assigned_to: cotb_user, assigned_by: judge) }
  let(:denied_docket_switch_task) { create(:docket_switch_denied_task, appeal: appeal, assigned_to: cotb_user, assigned_by: judge) }
  let(:docket_switch_task) { granted_docket_switch_task }
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
      let(:docket_switch_task) { denied_docket_switch_task }

      it "closes the DocketSwitchDeniedTask" do
        expect(docket_switch_task).to be_assigned

        subject

        expect(docket_switch_task).to be_completed
      end
    end

    context "disposition is granted or partially granted" do
      let(:docket_switch_task) { granted_docket_switch_task }

      context "when disposition is granted (full grant)" do
        let(:disposition) { "granted" }
        let(:granted_request_issue_ids) { nil }

        it "moves all request issues to a new appeal stream and archives the original appeal" do
          expect(docket_switch_task).to be_assigned

          subject

          # all request issues are copied to new appeal stream, accessible as new_docket_stream
          expect(docket_switch.new_docket_stream.request_issues.count).to eq appeal.request_issues.count

          # all old request issues closed
          expect(appeal.request_issues.map{ |ri| ri.reload.closed_status }.uniq).to eq ["docket_switch"]

          # Docket switch task gets completed
          expect(docket_switch_task).to be_completed

          # Appeal Status API shows original stream's status of archived
          expect(appeal.status.to_sym).to eq :archived
        end
      end

      context "when disposition is partially_granted" do
        let(:disposition) { "partially_granted" }
        let(:granted_request_issue_ids) { appeal.request_issues[0..1].map(&:id) }

        it "moves granted issues to new appeal stream and maintains original stream" do
          expect(docket_switch_task).to be_assigned

          subject

          # granted request issues are copied to new appeal stream
          expect(docket_switch.new_docket_stream.request_issues.count).to eq 2

          # granted old request issues closed
          expect(appeal.request_issues.map{ |ri| ri.reload.closed_status }.compact.uniq).to eq ["docket_switch"]
          expect(appeal.request_issues.active.count).to eq 1

          # Docket switch task gets completed
          expect(docket_switch_task).to be_completed

          # To do: Check for correct appeal status after task handling logic is implemented
        end
      end
    end
  end

  context "#copy_granted_request_issues!" do
    let(:disposition) { "granted" }
    subject { docket_switch.copy_granted_request_issues! }

    it "updates the appeal stream for every selected request issue" do
      expect(docket_switch.old_docket_stream.request_issues.size).to eq 3
      expect(docket_switch.new_docket_stream.request_issues.size).to eq 0
      subject
      expect(docket_switch.new_docket_stream.reload.request_issues.size).to eq 3
      expect(docket_switch.old_docket_stream.reload.request_issues.size).to eq 0
    end
  end

  context "#request_issues_for_switch" do
    let(:disposition) { "granted" }
    subject { docket_switch.request_issues_for_switch }

    it "returns the correct request issues" do
      expect(subject.size).to eq(granted_request_issue_ids.size)
    end
  end

  context "#granted_issues_present_if_partial" do
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
