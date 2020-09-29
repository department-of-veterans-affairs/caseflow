# frozen_string_literal: true

RSpec.describe DocketChange, type: :model do
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
  let(:docket_switch_mail_task) { create(:docket_switch_mail_task, appeal: appeal, assigned_to: cotb_user) }
  let(:disposition) { nil }
  let(:assigned_to_id) { nil }
  let(:granted_request_issue_ids) { appeal.request_issues.map(&:id) }
  let(:docket_change) do
    create(
      :docket_change,
      old_docket_stream: appeal,
      task: docket_switch_mail_task,
      disposition: disposition,
      granted_request_issue_ids: granted_request_issue_ids
    )
  end

  before do
    create(:staff, :judge_role, sdomainid: judge.reload.css_id)
    cotb_team.add_user(cotb_user)
  end

  context "#move_granted_request_issues" do
    let(:disposition) { "granted" }
    subject { docket_change.move_granted_request_issues }

    it "updates the appeal stream for every selected request issue" do
      expect(docket_change.old_docket_stream.request_issues.size).to eq 3
      expect(docket_change.new_docket_stream.request_issues.size).to eq 0
      subject
      expect(docket_change.new_docket_stream.reload.request_issues.size).to eq 3
      expect(docket_change.old_docket_stream.reload.request_issues.size).to eq 0
    end
  end
end
