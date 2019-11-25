# frozen_string_literal: true

describe DecisionReviewTasksForInactiveAppealsChecker, :postgres do
  before do
    seven_am_random_date = Time.new(2019, 3, 29, 7, 0, 0).in_time_zone
    Timecop.freeze(seven_am_random_date)
  end

  let(:education) { create(:business_line, url: "education") }
  let(:veteran) { create(:veteran) }
  let(:hlr) do
    create(:higher_level_review, benefit_type: "education", veteran_file_number: veteran.file_number)
  end
  let!(:request_issue) { create(:request_issue, :removed, decision_review: hlr) }
  let!(:task) { create(:higher_level_review_task, appeal: hlr, assigned_to: education) }
  let!(:board_grant_effectuation_task) { create(:board_grant_effectuation_task, appeal: hlr, assigned_to: education) }

  describe "#call" do
    it "reports one orphaned task" do
      subject.call

      expect(subject.report?).to eq(true)
      expect(subject.report).to eq("#{task.type} #{task.id} should be cancelled")
    end
  end
end
