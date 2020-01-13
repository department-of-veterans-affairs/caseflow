# frozen_string_literal: true

RSpec.describe PostDecisionMotion, type: :model do
  let(:lit_support_team) { LitigationSupport.singleton }
  let(:judge) { create(:user, full_name: "Judge User", css_id: "JUDGE_1") }
  let(:attorney) { create(:user) }
  let!(:judge_team) do
    JudgeTeam.create_for_judge(judge).tap { |jt| jt.add_user(attorney) }
  end
  let(:motions_atty) { create(:user, full_name: "Motions attorney") }
  let(:appeal) { create(:appeal) }
  let(:orig_decision_issues) do
    Array.new(3) do
      create(
        :decision_issue,
        decision_review: appeal,
        disposition: "denied"
      )
    end
  end
  let(:mtv_mail_task) { create(:vacate_motion_mail_task, appeal: appeal, assigned_to: motions_atty) }
  let(:task) { create(:judge_address_motion_to_vacate_task, :in_progress, parent: mtv_mail_task, assigned_to: judge) }
  let(:vacate_type) { nil }
  let(:disposition) { nil }
  let(:assigned_to_id) { nil }
  let(:hyperlink) { "https://va.gov/fake-link-to-file" }
  let(:instructions) { "formatted instructions from judge" }
  let(:vacated_decision_issue_ids) { orig_decision_issues.map(&:id) }
  let(:post_decision_motion) do
    create(
      :post_decision_motion,
      task: task,
      disposition: disposition,
      vacate_type: vacate_type,
      vacated_decision_issue_ids: vacated_decision_issue_ids
    )
  end

  before do
    create(:staff, :judge_role, sdomainid: judge.reload.css_id)
    lit_support_team.add_user(motions_atty)
  end

  context "handles creation of request issues" do
    let(:disposition) { "granted" }
    let(:vacate_type) { "vacate_and_readjudication" }

    it "creates a request issue for every selected decision issue" do
      expect(appeal.request_issues.length).to eq 0
      post_decision_motion.create_request_issues_for_vacature
      appeal.reload
      expect(appeal.request_issues.length).to eq 3
    end
  end
end
