# frozen_string_literal: true

describe MonthlyMetricsReportJob, :postgres do
  include_context "Metrics Reports"

  # rubocop:disable Metrics/LineLength
  let(:report) do
    "Monthly report 2019-02-01 to 2019-02-28\nPercentage of all cases certified with Caseflow: 100.0\nAppeals established within 7 days: 1 (100%)\nSupplemental Claims within 7 days: 1 (25.0%)\nHigher Level Reviews within 7 days: 2 (50.0%)\ntype,total,in_progress,cancelled,processed,established_within_seven_days,established_within_seven_days_percent,median,avg,max,min\nsupplemental_claims,4,1,1,2,1,25.0,373:30:00,373:30:00,743:00:00,04:00:00\nhigher_level_reviews,4,1,0,3,2,50.0,04:00:00,249:20:00,743:00:00,01:00:00\nrequest_issues_updates,3,0,1,2,1,33.33,384:00:00,384:00:00,767:00:00,01:00:00\n"
  end
  # rubocop:enable Metrics/LineLength

  describe "#perform" do
    before do
      allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| @slack_msg = first_arg }
    end

    it "sends message" do
      described_class.perform_now

      expect(@slack_msg).to eq(report)
    end
  end
end
